CREATE TABLE IF NOT EXISTS notes (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    text text NOT NULL CHECK (char_length(text) BETWEEN 1 AND 500),
    created_at timestamptz NOT NULL DEFAULT now()
);
