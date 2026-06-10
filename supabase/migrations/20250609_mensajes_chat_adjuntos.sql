-- Columnas para adjuntos en el chat grupal (StudyMatch)
ALTER TABLE mensajes_chat
  ADD COLUMN IF NOT EXISTS archivo_url TEXT,
  ADD COLUMN IF NOT EXISTS tipo_archivo TEXT,
  ADD COLUMN IF NOT EXISTS nombre_archivo TEXT;

-- Bucket de archivos del chat (si no existe)
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat_archivos', 'chat_archivos', true)
ON CONFLICT (id) DO NOTHING;

-- Lectura pública de archivos del chat
CREATE POLICY IF NOT EXISTS "chat_archivos_public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'chat_archivos');

-- Subida por usuarios autenticados
CREATE POLICY IF NOT EXISTS "chat_archivos_auth_upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'chat_archivos');
