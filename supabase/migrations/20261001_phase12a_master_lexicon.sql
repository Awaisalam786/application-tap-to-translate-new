-- =============================================================================
-- Phase 12A: German Master Vocabulary & Admin Lexicon Management Schema
-- Date: 2026-10-01
-- Description:
--   Additive schema establishing the clean, original, human-reviewed
--   A1-B2 German vocabulary database, language-specific translation verification,
--   curated synonyms, original learning examples, and hardened role-based
--   Row-Level Security (RLS) with parent-enforced public visibility.
--
-- STRICT PRESERVATION INVARIANT:
--   Phase 11A tables (lexicon_entries, central_translation_cache, translation_requests)
--   are strictly UNTOUCHED and NOT modified in any way by this migration.
-- =============================================================================

-- Ensure required extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. admin_users
-- Authorized personnel managing and verifying the master dictionary.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('superadmin', 'reviewer', 'editor')),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_users_role ON public.admin_users(role);
CREATE INDEX IF NOT EXISTS idx_admin_users_active ON public.admin_users(is_active);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. master_lexicon_entries
-- Authoritative German lemma records with grammatical metadata and CEFR level.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.master_lexicon_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lemma TEXT NOT NULL,
    normalized_lemma TEXT NOT NULL,
    part_of_speech TEXT NOT NULL CHECK (
        part_of_speech IN (
            'noun', 'verb', 'adjective', 'adverb',
            'pronoun', 'preposition', 'conjunction',
            'interjection', 'particle', 'other'
        )
    ),
    gender TEXT CHECK (gender IN ('der', 'die', 'das', 'none')),
    plural_form TEXT,
    cefr_level TEXT NOT NULL DEFAULT 'unclassified' CHECK (
        cefr_level IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'unclassified')
    ),
    status TEXT NOT NULL DEFAULT 'draft' CHECK (
        status IN ('draft', 'review', 'verified', 'rejected')
    ),
    frequency_index INTEGER DEFAULT 0,
    source_type TEXT NOT NULL DEFAULT 'manual_entry' CHECK (
        source_type IN ('manual_entry', 'candidate_import', 'curated_expansion', 'community_submission')
    ),
    provenance TEXT,
    created_by UUID REFERENCES public.admin_users(id),
    reviewed_by UUID REFERENCES public.admin_users(id),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Unique canonical lemma per part of speech to avoid duplicate homographs of the same type
    CONSTRAINT uq_master_lemma_pos UNIQUE (normalized_lemma, part_of_speech)
);

CREATE INDEX IF NOT EXISTS idx_master_normalized_lemma ON public.master_lexicon_entries(normalized_lemma);
CREATE INDEX IF NOT EXISTS idx_master_cefr_level ON public.master_lexicon_entries(cefr_level);
CREATE INDEX IF NOT EXISTS idx_master_pos ON public.master_lexicon_entries(part_of_speech);
CREATE INDEX IF NOT EXISTS idx_master_status ON public.master_lexicon_entries(status);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. lexicon_translations
-- Multi-language translations with language-independent verification status.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.lexicon_translations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entry_id UUID NOT NULL REFERENCES public.master_lexicon_entries(id) ON DELETE CASCADE,
    target_lang TEXT NOT NULL CHECK (target_lang IN ('en', 'ur', 'fa', 'ar')),
    translation TEXT NOT NULL,
    context_notes TEXT,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (
        status IN ('draft', 'review', 'verified', 'rejected')
    ),
    source_type TEXT NOT NULL DEFAULT 'manual' CHECK (
        source_type IN ('manual', 'candidate_import', 'provider_suggestion', 'human_curated')
    ),
    provider TEXT DEFAULT 'human',
    verified_by UUID REFERENCES public.admin_users(id),
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Prevent duplicate translations for the same entry, language, and string
    CONSTRAINT uq_entry_target_translation UNIQUE (entry_id, target_lang, translation)
);

CREATE INDEX IF NOT EXISTS idx_translations_entry_id ON public.lexicon_translations(entry_id);
CREATE INDEX IF NOT EXISTS idx_translations_entry_lang ON public.lexicon_translations(entry_id, target_lang);
CREATE INDEX IF NOT EXISTS idx_translations_lang_status ON public.lexicon_translations(target_lang, status);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. lexicon_senses
-- Distinct semantic senses and definitions for polysemous German words.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.lexicon_senses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entry_id UUID NOT NULL REFERENCES public.master_lexicon_entries(id) ON DELETE CASCADE,
    sense_order INTEGER NOT NULL DEFAULT 1,
    definition_de TEXT NOT NULL,
    definition_en TEXT,
    context_domain TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_entry_sense_order UNIQUE (entry_id, sense_order)
);

CREATE INDEX IF NOT EXISTS idx_senses_entry_id ON public.lexicon_senses(entry_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. lexicon_synonyms
-- Curated linguistic relationships. Not automatically treated as translations.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.lexicon_synonyms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entry_id UUID NOT NULL REFERENCES public.master_lexicon_entries(id) ON DELETE CASCADE,
    synonym_word TEXT NOT NULL,
    nuance_note TEXT,
    status TEXT NOT NULL DEFAULT 'draft' CHECK (
        status IN ('draft', 'review', 'verified', 'rejected')
    ),
    source_type TEXT NOT NULL DEFAULT 'manual' CHECK (
        source_type IN ('manual', 'candidate_import', 'curated')
    ),
    reviewed_by UUID REFERENCES public.admin_users(id),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_entry_synonym UNIQUE (entry_id, synonym_word)
);

CREATE INDEX IF NOT EXISTS idx_synonyms_entry_id ON public.lexicon_synonyms(entry_id);
CREATE INDEX IF NOT EXISTS idx_synonyms_status ON public.lexicon_synonyms(status);

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. lexicon_examples
-- Original and human-curated pedagogical learning example sentences.
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.lexicon_examples (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entry_id UUID NOT NULL REFERENCES public.master_lexicon_entries(id) ON DELETE CASCADE,
    sentence_de TEXT NOT NULL,
    sentence_en TEXT,
    sentence_ur TEXT,
    cefr_level TEXT CHECK (cefr_level IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2')),
    status TEXT NOT NULL DEFAULT 'draft' CHECK (
        status IN ('draft', 'review', 'verified', 'rejected')
    ),
    source_type TEXT NOT NULL DEFAULT 'original_curated' CHECK (
        source_type IN ('original_curated', 'candidate_import', 'educator_submission')
    ),
    created_by UUID REFERENCES public.admin_users(id),
    reviewed_by UUID REFERENCES public.admin_users(id),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_examples_entry_id ON public.lexicon_examples(entry_id);
CREATE INDEX IF NOT EXISTS idx_examples_status ON public.lexicon_examples(status);
CREATE INDEX IF NOT EXISTS idx_examples_cefr ON public.lexicon_examples(cefr_level);

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. Automated updated_at Triggers
-- ─────────────────────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_admin_users_updated_at ON public.admin_users;
CREATE TRIGGER trg_admin_users_updated_at
    BEFORE UPDATE ON public.admin_users
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_master_lexicon_updated_at ON public.master_lexicon_entries;
CREATE TRIGGER trg_master_lexicon_updated_at
    BEFORE UPDATE ON public.master_lexicon_entries
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_lexicon_translations_updated_at ON public.lexicon_translations;
CREATE TRIGGER trg_lexicon_translations_updated_at
    BEFORE UPDATE ON public.lexicon_translations
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_lexicon_senses_updated_at ON public.lexicon_senses;
CREATE TRIGGER trg_lexicon_senses_updated_at
    BEFORE UPDATE ON public.lexicon_senses
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_lexicon_synonyms_updated_at ON public.lexicon_synonyms;
CREATE TRIGGER trg_lexicon_synonyms_updated_at
    BEFORE UPDATE ON public.lexicon_synonyms
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_lexicon_examples_updated_at ON public.lexicon_examples;
CREATE TRIGGER trg_lexicon_examples_updated_at
    BEFORE UPDATE ON public.lexicon_examples
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ─────────────────────────────────────────────────────────────────────────────
-- 8. Hardened Security-Definer Helper Functions (Explicit safe search_path)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_active_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.admin_users
        WHERE id = auth.uid() AND is_active = true
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_admin_role()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT role INTO user_role FROM public.admin_users
    WHERE id = auth.uid() AND is_active = true;
    RETURN user_role;
END;
$$;

CREATE OR REPLACE FUNCTION public.is_reviewer_or_superadmin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.admin_users
        WHERE id = auth.uid() AND is_active = true AND role IN ('superadmin', 'reviewer')
    );
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 9. Row-Level Security (RLS) & Granular Role Policies
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.master_lexicon_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lexicon_translations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lexicon_senses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lexicon_synonyms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lexicon_examples ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- Policies for: admin_users
-- -----------------------------------------------------------------------------
CREATE POLICY "Admins can view admin list"
    ON public.admin_users
    FOR SELECT
    TO authenticated
    USING (public.is_active_admin());

CREATE POLICY "Superadmins can manage admin users"
    ON public.admin_users
    FOR ALL
    TO authenticated
    USING (public.get_admin_role() = 'superadmin')
    WITH CHECK (public.get_admin_role() = 'superadmin');

-- -----------------------------------------------------------------------------
-- Policies for: master_lexicon_entries
-- -----------------------------------------------------------------------------
-- PUBLIC / READER:
CREATE POLICY "Public read on verified master lexicon"
    ON public.master_lexicon_entries
    FOR SELECT
    USING (status = 'verified');

-- ADMIN READ:
CREATE POLICY "Active admins read all master entries"
    ON public.master_lexicon_entries
    FOR SELECT
    TO authenticated
    USING (public.is_active_admin());

-- INSERT:
CREATE POLICY "Reviewers and superadmins insert master entries"
    ON public.master_lexicon_entries
    FOR INSERT
    TO authenticated
    WITH CHECK (public.is_reviewer_or_superadmin());

CREATE POLICY "Editors insert draft or review master entries"
    ON public.master_lexicon_entries
    FOR INSERT
    TO authenticated
    WITH CHECK (
        public.get_admin_role() = 'editor'
        AND status IN ('draft', 'review')
    );

-- UPDATE:
CREATE POLICY "Reviewers and superadmins update any master entry"
    ON public.master_lexicon_entries
    FOR UPDATE
    TO authenticated
    USING (public.is_reviewer_or_superadmin())
    WITH CHECK (public.is_reviewer_or_superadmin());

CREATE POLICY "Editors update non-verified master entries without verifying"
    ON public.master_lexicon_entries
    FOR UPDATE
    TO authenticated
    USING (
        public.get_admin_role() = 'editor'
        AND status != 'verified'
    )
    WITH CHECK (
        public.get_admin_role() = 'editor'
        AND status IN ('draft', 'review', 'rejected')
    );

-- DELETE:
CREATE POLICY "Superadmins delete master entries"
    ON public.master_lexicon_entries
    FOR DELETE
    TO authenticated
    USING (public.get_admin_role() = 'superadmin');

-- -----------------------------------------------------------------------------
-- Policies for: lexicon_translations
-- -----------------------------------------------------------------------------
-- PUBLIC / READER:
-- Translation is visible to public ONLY when translation itself is verified
-- AND its parent master_lexicon_entries record is verified.
CREATE POLICY "Public read on verified translations"
    ON public.lexicon_translations
    FOR SELECT
    USING (
        status = 'verified'
        AND EXISTS (
            SELECT 1 FROM public.master_lexicon_entries
            WHERE id = lexicon_translations.entry_id
              AND status = 'verified'
        )
    );

-- ADMIN READ:
CREATE POLICY "Active admins read all translations"
    ON public.lexicon_translations
    FOR SELECT
    TO authenticated
    USING (public.is_active_admin());

-- INSERT:
CREATE POLICY "Reviewers and superadmins insert translations"
    ON public.lexicon_translations
    FOR INSERT
    TO authenticated
    WITH CHECK (public.is_reviewer_or_superadmin());

CREATE POLICY "Editors insert draft or review translations"
    ON public.lexicon_translations
    FOR INSERT
    TO authenticated
    WITH CHECK (
        public.get_admin_role() = 'editor'
        AND status IN ('draft', 'review')
    );

-- UPDATE:
CREATE POLICY "Reviewers and superadmins update translations"
    ON public.lexicon_translations
    FOR UPDATE
    TO authenticated
    USING (public.is_reviewer_or_superadmin())
    WITH CHECK (public.is_reviewer_or_superadmin());

CREATE POLICY "Editors update non-verified translations without verifying"
    ON public.lexicon_translations
    FOR UPDATE
    TO authenticated
    USING (
        public.get_admin_role() = 'editor'
        AND status != 'verified'
    )
    WITH CHECK (
        public.get_admin_role() = 'editor'
        AND status IN ('draft', 'review', 'rejected')
    );

-- DELETE:
CREATE POLICY "Superadmins delete translations"
    ON public.lexicon_translations
    FOR DELETE
    TO authenticated
    USING (public.get_admin_role() = 'superadmin');

-- -----------------------------------------------------------------------------
-- Policies for: lexicon_senses
-- -----------------------------------------------------------------------------
-- PUBLIC / READER:
-- Senses are visible to public ONLY when parent master_lexicon_entries is verified.
CREATE POLICY "Public read on senses for verified entries"
    ON public.lexicon_senses
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.master_lexicon_entries
            WHERE id = lexicon_senses.entry_id
              AND status = 'verified'
        )
    );

-- ADMIN READ:
CREATE POLICY "Active admins read all senses"
    ON public.lexicon_senses
    FOR SELECT
    TO authenticated
    USING (public.is_active_admin());

-- INSERT:
CREATE POLICY "Reviewers and superadmins insert senses"
    ON public.lexicon_senses
    FOR INSERT
    TO authenticated
    WITH CHECK (public.is_reviewer_or_superadmin());

CREATE POLICY "Editors insert senses for non-verified entries"
    ON public.lexicon_senses
    FOR INSERT
    TO authenticated
    WITH CHECK (
        public.get_admin_role() = 'editor'
        AND EXISTS (
            SELECT 1 FROM public.master_lexicon_entries
            WHERE id = lexicon_senses.entry_id
              AND status != 'verified'
        )
    );

-- UPDATE:
CREATE POLICY "Reviewers and superadmins update senses"
    ON public.lexicon_senses
    FOR UPDATE
    TO authenticated
    USING (public.is_reviewer_or_superadmin())
    WITH CHECK (public.is_reviewer_or_superadmin());

CREATE POLICY "Editors update senses for non-verified entries"
    ON public.lexicon_senses
    FOR UPDATE
    TO authenticated
    USING (
        public.get_admin_role() = 'editor'
        AND EXISTS (
            SELECT 1 FROM public.master_lexicon_entries
            WHERE id = lexicon_senses.entry_id
              AND status != 'verified'
        )
    )
    WITH CHECK (
        public.get_admin_role() = 'editor'
        AND EXISTS (
            SELECT 1 FROM public.master_lexicon_entries
            WHERE id = lexicon_senses.entry_id
              AND status != 'verified'
        )
    );

-- DELETE:
CREATE POLICY "Superadmins delete senses"
    ON public.lexicon_senses
    FOR DELETE
    TO authenticated
    USING (public.get_admin_role() = 'superadmin');

-- -----------------------------------------------------------------------------
-- Policies for: lexicon_synonyms
-- -----------------------------------------------------------------------------
-- PUBLIC / READER:
-- Synonym is visible to public ONLY when synonym itself is verified
-- AND its parent master_lexicon_entries record is verified.
CREATE POLICY "Public read on verified synonyms"
    ON public.lexicon_synonyms
    FOR SELECT
    USING (
        status = 'verified'
        AND EXISTS (
            SELECT 1 FROM public.master_lexicon_entries
            WHERE id = lexicon_synonyms.entry_id
              AND status = 'verified'
        )
    );

-- ADMIN READ:
CREATE POLICY "Active admins read all synonyms"
    ON public.lexicon_synonyms
    FOR SELECT
    TO authenticated
    USING (public.is_active_admin());

-- INSERT:
CREATE POLICY "Reviewers and superadmins insert synonyms"
    ON public.lexicon_synonyms
    FOR INSERT
    TO authenticated
    WITH CHECK (public.is_reviewer_or_superadmin());

CREATE POLICY "Editors insert draft or review synonyms"
    ON public.lexicon_synonyms
    FOR INSERT
    TO authenticated
    WITH CHECK (
        public.get_admin_role() = 'editor'
        AND status IN ('draft', 'review')
    );

-- UPDATE:
CREATE POLICY "Reviewers and superadmins update synonyms"
    ON public.lexicon_synonyms
    FOR UPDATE
    TO authenticated
    USING (public.is_reviewer_or_superadmin())
    WITH CHECK (public.is_reviewer_or_superadmin());

CREATE POLICY "Editors update non-verified synonyms without verifying"
    ON public.lexicon_synonyms
    FOR UPDATE
    TO authenticated
    USING (
        public.get_admin_role() = 'editor'
        AND status != 'verified'
    )
    WITH CHECK (
        public.get_admin_role() = 'editor'
        AND status IN ('draft', 'review', 'rejected')
    );

-- DELETE:
CREATE POLICY "Superadmins delete synonyms"
    ON public.lexicon_synonyms
    FOR DELETE
    TO authenticated
    USING (public.get_admin_role() = 'superadmin');

-- -----------------------------------------------------------------------------
-- Policies for: lexicon_examples
-- -----------------------------------------------------------------------------
-- PUBLIC / READER:
-- Example is visible to public ONLY when example itself is verified
-- AND its parent master_lexicon_entries record is verified.
CREATE POLICY "Public read on verified examples"
    ON public.lexicon_examples
    FOR SELECT
    USING (
        status = 'verified'
        AND EXISTS (
            SELECT 1 FROM public.master_lexicon_entries
            WHERE id = lexicon_examples.entry_id
              AND status = 'verified'
        )
    );

-- ADMIN READ:
CREATE POLICY "Active admins read all examples"
    ON public.lexicon_examples
    FOR SELECT
    TO authenticated
    USING (public.is_active_admin());

-- INSERT:
CREATE POLICY "Reviewers and superadmins insert examples"
    ON public.lexicon_examples
    FOR INSERT
    TO authenticated
    WITH CHECK (public.is_reviewer_or_superadmin());

CREATE POLICY "Editors insert draft or review examples"
    ON public.lexicon_examples
    FOR INSERT
    TO authenticated
    WITH CHECK (
        public.get_admin_role() = 'editor'
        AND status IN ('draft', 'review')
    );

-- UPDATE:
CREATE POLICY "Reviewers and superadmins update examples"
    ON public.lexicon_examples
    FOR UPDATE
    TO authenticated
    USING (public.is_reviewer_or_superadmin())
    WITH CHECK (public.is_reviewer_or_superadmin());

CREATE POLICY "Editors update non-verified examples without verifying"
    ON public.lexicon_examples
    FOR UPDATE
    TO authenticated
    USING (
        public.get_admin_role() = 'editor'
        AND status != 'verified'
    )
    WITH CHECK (
        public.get_admin_role() = 'editor'
        AND status IN ('draft', 'review', 'rejected')
    );

-- DELETE:
CREATE POLICY "Superadmins delete examples"
    ON public.lexicon_examples
    FOR DELETE
    TO authenticated
    USING (public.get_admin_role() = 'superadmin');
