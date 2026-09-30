-- =============================================================================
-- Phase 11A: Smart Online Translation Fallback & Supabase Central Lexicon Schema
-- Date: 2026-09-30
-- Description:
--   Creates central lexicon tables, caching structures, request logs,
--   indexes, unique constraints, and Row-Level Security (RLS) policies.
-- =============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. lexicon_entries
-- Curated, community, and machine-generated verified dictionary entries.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.lexicon_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    normalized_word TEXT NOT NULL,
    source_language TEXT NOT NULL DEFAULT 'de',
    target_language TEXT NOT NULL,
    translation TEXT NOT NULL,
    part_of_speech TEXT,
    definition TEXT,
    example_sentence TEXT,
    source TEXT NOT NULL DEFAULT 'online_fallback',
    status TEXT NOT NULL DEFAULT 'machine_generated', -- 'verified', 'pending', 'machine_generated'
    hit_count INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Prevent duplicate translations for the same word and language pair
    CONSTRAINT uq_lexicon_word_pair UNIQUE (normalized_word, source_language, target_language)
);

-- Fast lookup indexes
CREATE INDEX IF NOT EXISTS idx_lexicon_entries_lookup
    ON public.lexicon_entries (normalized_word, target_language);

CREATE INDEX IF NOT EXISTS idx_lexicon_entries_status
    ON public.lexicon_entries (status);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. central_translation_cache
-- Central cache storing rapid lookups from online translation providers.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.central_translation_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cache_key TEXT NOT NULL UNIQUE, -- e.g. "deutschland_en", "mädchen_ur"
    normalized_word TEXT NOT NULL,
    source_language TEXT NOT NULL DEFAULT 'de',
    target_language TEXT NOT NULL,
    translation TEXT NOT NULL,
    provider TEXT NOT NULL DEFAULT 'online', -- e.g. "mymemory"
    source TEXT NOT NULL DEFAULT 'online_fallback',
    status TEXT NOT NULL DEFAULT 'machine_generated',
    hit_count INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Fast key and word lookups
CREATE INDEX IF NOT EXISTS idx_central_cache_key
    ON public.central_translation_cache (cache_key);

CREATE INDEX IF NOT EXISTS idx_central_cache_word
    ON public.central_translation_cache (normalized_word, target_language);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. translation_requests
-- Request log for analytics, missing word frequency, and audit trails.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.translation_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    raw_word TEXT NOT NULL,
    normalized_word TEXT NOT NULL,
    source_language TEXT NOT NULL DEFAULT 'de',
    target_language TEXT NOT NULL,
    resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_source TEXT, -- 'local_lexicon', 'local_cache', 'supabase_central_lexicon', 'online_fallback', 'not_found'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_translation_requests_word
    ON public.translation_requests (normalized_word, target_language);

CREATE INDEX IF NOT EXISTS idx_translation_requests_resolved
    ON public.translation_requests (resolved);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Automatic updated_at Trigger
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_lexicon_entries_updated_at ON public.lexicon_entries;
CREATE TRIGGER trg_lexicon_entries_updated_at
    BEFORE UPDATE ON public.lexicon_entries
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_central_cache_updated_at ON public.central_translation_cache;
CREATE TRIGGER trg_central_cache_updated_at
    BEFORE UPDATE ON public.central_translation_cache
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Row Level Security (RLS) Policies
-- Enables client read/write with anon key while protecting schema integrity.
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.lexicon_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.central_translation_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.translation_requests ENABLE ROW LEVEL SECURITY;

-- Allow read access to all users (anonymous and authenticated)
CREATE POLICY "Public Read Access on Lexicon Entries"
    ON public.lexicon_entries
    FOR SELECT
    USING (true);

CREATE POLICY "Public Read Access on Central Cache"
    ON public.central_translation_cache
    FOR SELECT
    USING (true);

-- Allow inserting new translations from online fallback into central cache & entries
CREATE POLICY "Anon Insert Access on Central Cache"
    ON public.central_translation_cache
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Anon Insert Access on Lexicon Entries"
    ON public.lexicon_entries
    FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Anon Update Access on Central Cache"
    ON public.central_translation_cache
    FOR UPDATE
    USING (true)
    WITH CHECK (true);

-- Allow logging translation requests
CREATE POLICY "Anon Insert Access on Translation Requests"
    ON public.translation_requests
    FOR INSERT
    WITH CHECK (true);
