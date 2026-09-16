-- =========================================================
-- Enquête logement & foyer — schéma Supabase (PostgreSQL)
-- À exécuter dans l'éditeur SQL du projet Supabase
-- =========================================================

-- Extension nécessaire pour gen_random_uuid()
create extension if not exists pgcrypto;

create table if not exists public.reponses_menages (
  id                uuid primary key default gen_random_uuid(),
  created_at        timestamptz not null default now(),
  nb_personnes      integer not null check (nb_personnes >= 1),
  nb_enfants        integer not null default 0 check (nb_enfants >= 0),
  type_logement     text not null check (type_logement in ('appartement', 'maison', 'autre')),
  code_postal       text not null check (code_postal ~ '^[0-9]{5}$'),
  tranche_revenu    text not null,
  commentaire       text,
  consentement_rgpd boolean not null check (consentement_rgpd = true)
);

comment on table public.reponses_menages is 'Réponses au questionnaire logement & foyer — données personnelles, accès restreint.';

-- Row Level Security : activé, personne n'a d'accès par défaut
alter table public.reponses_menages enable row level security;

-- Le public (rôle anon, via la clé anon) peut UNIQUEMENT insérer une réponse.
-- Il ne peut ni lire, ni modifier, ni supprimer.
create policy "Le public peut soumettre une réponse"
  on public.reponses_menages
  for insert
  to anon
  with check (true);

-- Seuls les utilisateurs authentifiés (l'administrateur, créé manuellement
-- dans Authentication > Users, sans inscription publique ouverte) peuvent lire.
create policy "L'administrateur authentifié peut lire les réponses"
  on public.reponses_menages
  for select
  to authenticated
  using (true);

-- Aucune policy update/delete : personne ne peut modifier ou supprimer via l'API.
-- (Un accès direct via le dashboard Supabase avec le rôle service_role reste
-- toujours possible pour la maintenance, RLS ne s'applique pas au service_role.)

-- =========================================================
-- Étapes manuelles à faire dans le dashboard Supabase :
-- 1. Authentication > Providers : désactiver "Allow new users to sign up"
--    (pour empêcher toute création de compte publique).
-- 2. Authentication > Users : créer manuellement le compte administrateur
--    (email + mot de passe), c'est le seul compte qui existera.
-- 3. Project Settings > Data API : noter l'URL du projet et la clé "anon public".
-- 4. Project Settings > General : choisir la région d'hébergement EU
--    au moment de la création du projet (irréversible ensuite).
-- =========================================================
