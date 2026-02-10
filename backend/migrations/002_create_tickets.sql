CREATE TABLE IF NOT EXISTS tickets (
    id CHAR(36) NOT NULL PRIMARY KEY,
    inv_gate_id VARCHAR(100) NOT NULL,
    source_id INT NOT NULL,
    creator_id INT NOT NULL,
    customer_id INT NOT NULL,
    category_id INT NOT NULL,
    type_id INT NOT NULL,
    priority_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    creator_email VARCHAR(190) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_inv_gate_id (inv_gate_id),
    INDEX idx_creator_email (creator_email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

