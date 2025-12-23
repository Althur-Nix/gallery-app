require("dotenv").config();
const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
const multer = require("multer");
const path = require("path");

const app = express();
const SECRET_KEY = process.env.SECRET_KEY || "default_secret_key";
const PORT = process.env.PORT || 3000;
// Koneksi database langsung di sini
const db = mysql.createConnection({
  host: "localhost",
  user: "root",
  password: "",
  database: "gallery_db",
});



// Middleware
app.use(express.json());
app.use(cors({ origin: "*" }));
app.use("/uploads", express.static("uploads")); // Akses publik folder uploads

// Middleware untuk verifikasi token JWT
function authenticateToken(req, res, next) {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];
  if (!token) return res.status(401).json({ message: "Token not provided" });

  jwt.verify(token, SECRET_KEY, (err, user) => {
    if (err) return res.status(403).json({ message: "Invalid token" });
    req.user = user;
    next();
  });
}




db.connect((err) => {
    if (err) {
        console.error("❌ Gagal koneksi database:", err);
        return;
    }
    console.log("✅ Terkoneksi ke MySQL");
});

// Multer untuk upload gambar
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, "uploads/"),
    filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

// =====================================
// =========== AUTH SYSTEM ============
// =====================================
app.post("/register", async (req, res) => {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
        return res.status(400).json({ error: "Semua field wajib diisi" });
    }

    const checkQuery = "SELECT * FROM users WHERE email = ? OR username = ?";
    db.query(checkQuery, [email, username], async (err, results) => {
        if (err) return res.status(500).json({ error: "Database error" });
        if (results.length > 0) return res.status(400).json({ error: "Email/Username sudah terdaftar" });

        const hashedPassword = await bcrypt.hash(password, 10);
        const insertQuery = "INSERT INTO users (username, email, password) VALUES (?, ?, ?)";
        db.query(insertQuery, [username, email, hashedPassword], (err, result) => {
            if (err) return res.status(500).json({ error: "Database error" });
            res.status(201).json({ message: "User berhasil register" });
        });
    });
});

app.post("/login", (req, res) => {
    const { usernameOrEmail, password } = req.body;
    if (!usernameOrEmail || !password) return res.status(400).json({ error: "Semua field wajib diisi" });

    const query = "SELECT * FROM users WHERE username = ? OR email = ?";
    db.query(query, [usernameOrEmail, usernameOrEmail], async (err, results) => {
        if (err) return res.status(500).json({ error: "Database error" });
        if (results.length === 0) return res.status(401).json({ error: "Akun tidak ditemukan" });

        const user = results[0];
        const isValid = await bcrypt.compare(password, user.password);
        if (!isValid) return res.status(401).json({ error: "Password salah" });

        const token = jwt.sign({ id: user.id, username: user.username }, SECRET_KEY, { expiresIn: "1h" });
        res.json({ message: "Login sukses", token, user: { id: user.id, username: user.username, email: user.email } });
    });
});

// =====================================
// ======== FITUR UPLOAD FOTO =========
// =====================================
app.post("/upload", authenticateToken, upload.single("img"), (req, res) => {
    const userId = req.user.id;

    if (!req.file) return res.status(400).json({ error: "Gambar tidak ditemukan" });

    const imageUrl = req.file.filename;
    const query = "INSERT INTO photos (user_id, image_url) VALUES (?, ?)";
    db.query(query, [userId, imageUrl], (err, result) => {
        if (err) return res.status(500).json({ error: "Database error" });
        res.status(201).json({ message: "Upload berhasil", imageUrl });
    });
});

// =====================================
// ==== GET Semua Foto + Statistik ====
// =====================================
app.get("/photos", authenticateToken, (req, res) => {
    const userId = req.user.id;

    const query = `
        SELECT 
            p.id, 
            p.image_url, 
            p.created_at, 
            u.username,
            (SELECT COUNT(*) FROM likes WHERE photo_id = p.id AND deleted_at IS NULL) AS likeCount,
            (SELECT COUNT(*) FROM comments WHERE photo_id = p.id) AS commentCount,
            EXISTS (
                SELECT 1 
                FROM likes 
                WHERE photo_id = p.id AND user_id = ? AND deleted_at IS NULL
            ) AS isLiked
        FROM photos p
        JOIN users u ON p.user_id = u.id
        ORDER BY p.created_at DESC
    `;

    db.query(query, [userId], (err, results) => {
        if (err) return res.status(500).json({ error: "Database error" });
        res.json(results);
    });
});


// =====================================
// ========== KOMENTAR ================
// =====================================
app.post("/comments", authenticateToken, (req, res) => {
    const { photoId, comment } = req.body;
    const userId = req.user.id;

    if (!photoId || !comment) return res.status(400).json({ error: "Komentar dan photoId wajib diisi" });

    const query = "INSERT INTO comments (user_id, photo_id, comment) VALUES (?, ?, ?)";
    db.query(query, [userId, photoId, comment], (err, result) => {
        if (err) return res.status(500).json({ error: "Database error" });
        res.status(201).json({ message: "Komentar ditambahkan" });
    });
});

app.get("/comments/:photoId", (req, res) => {
    const { photoId } = req.params;
    const query = `
        SELECT comments.id, comments.comment, comments.created_at, comments.user_id, users.username 
        FROM comments 
        JOIN users ON comments.user_id = users.id 
        WHERE comments.photo_id = ?
        ORDER BY comments.created_at DESC
    `;
    db.query(query, [photoId], (err, results) => {
        if (err) return res.status(500).json({ error: "Database error" });
        res.json(results);
    });
});

// Hapus komentar (hanya boleh oleh pemilik komentar)
app.delete("/comments/:id", authenticateToken, (req, res) => {
    const commentId = req.params.id;
    const userId = req.user.id;

    // Pastikan hanya pemilik komentar yang bisa hapus
    const checkQuery = "SELECT * FROM comments WHERE id = ? AND user_id = ?";
    db.query(checkQuery, [commentId, userId], (err, results) => {
        if (err) return res.status(500).json({ error: "Database error" });
        if (results.length === 0) return res.status(403).json({ error: "Tidak diizinkan menghapus komentar ini" });

        // Hard delete
        const deleteQuery = "DELETE FROM comments WHERE id = ?";
        db.query(deleteQuery, [commentId], (err) => {
            if (err) return res.status(500).json({ error: "Gagal menghapus komentar" });
            res.json({ message: "Komentar berhasil dihapus", success: true });
        });
    });
});

// =====================================
// ============== LIKE =================
// =====================================
// Ganti semua endpoint like dengan ini:
app.post("/like", authenticateToken, (req, res) => {
    const userId = req.user.id;
    const { photoId } = req.body;
    
    console.log('User ID:', userId, 'Photo ID:', photoId);
    if (!photoId) return res.status(400).json({ error: "photoId wajib diisi" });

    // Cek apakah sudah like
    const checkQuery = `SELECT * FROM likes WHERE user_id = ? AND photo_id = ?`;
    db.query(checkQuery, [userId, photoId], (err, results) => {
        if (err) return res.status(500).json({ error: "Database error" });

        const like = results[0];
if (like && like.deleted_at === null) {
    // Sudah like → unlike (soft delete)
    const updateQuery = `UPDATE likes SET deleted_at = NOW() WHERE id = ?`;
    db.query(updateQuery, [like.id], (err) => {
        if (err) return res.status(500).json({ error: "Gagal unlike" });
        return res.json({ message: "Unlike berhasil", success: true });
    });
} else if (like && like.deleted_at !== null) {
    // Sudah unlike → like lagi (reset deleted_at)
    const resetQuery = `UPDATE likes SET deleted_at = NULL WHERE id = ?`;
    db.query(resetQuery, [like.id], (err) => {
        if (err) return res.status(500).json({ error: "Gagal like ulang" });
        return res.json({ message: "Like berhasil", success: true });
    });
} else {
    // Belum pernah like → insert baru
    const insertQuery = `INSERT INTO likes (user_id, photo_id) VALUES (?, ?)`;
    db.query(insertQuery, [userId, photoId], (err) => {
        if (err) return res.status(500).json({ error: "Gagal like" });
        return res.status(201).json({ message: "Like berhasil", success: true });
    });
}
// ...existing code...
    });
});







// =====================================
// ============ SERVER START ==========
// =====================================
app.get("/", (req, res) => {
    res.send("Server is running...");
});

app.listen(PORT, "0.0.0.0", () => {
    console.log(`🚀 Server berjalan di semua IP pada port ${PORT}`);
});
