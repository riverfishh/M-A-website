-- Run once in Supabase > SQL Editor.
-- After creating your admin user in Authentication > Users, run:
--   insert into admins(user_id) values ('<that user's UUID>');
create table admins(user_id uuid primary key references auth.users on delete cascade);
alter table admins enable row level security;
create function is_admin() returns boolean language sql security definer stable set search_path=public
as $$ select exists(select 1 from admins where user_id=auth.uid()) $$;
create table papers(id uuid primary key default gen_random_uuid(),title text not null,summary text not null,author text,category text,published_on date,file_path text not null,file_name text not null,created_at timestamptz default now());
create table gallery_images(id uuid primary key default gen_random_uuid(),file_path text not null,caption text,sort_order int not null default 0,created_at timestamptz default now());
alter table papers enable row level security; alter table gallery_images enable row level security;
create policy "read" on papers for select using (true);
create policy "ins" on papers for insert to authenticated with check (is_admin());
create policy "upd" on papers for update to authenticated using (is_admin()) with check (is_admin());
create policy "del" on papers for delete to authenticated using (is_admin());
create policy "read" on gallery_images for select using (true);
create policy "ins" on gallery_images for insert to authenticated with check (is_admin());
create policy "upd" on gallery_images for update to authenticated using (is_admin()) with check (is_admin());
create policy "del" on gallery_images for delete to authenticated using (is_admin());
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values
 ('papers','papers',true,20971520,array['application/pdf','application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
 ('gallery','gallery',true,15728640,array['image/jpeg','image/png','image/webp']) on conflict do nothing;
create policy "pub read" on storage.objects for select using (bucket_id in ('papers','gallery'));
create policy "adm ins" on storage.objects for insert to authenticated with check (bucket_id in ('papers','gallery') and is_admin());
create policy "adm upd" on storage.objects for update to authenticated using (bucket_id in ('papers','gallery') and is_admin());
create policy "adm del" on storage.objects for delete to authenticated using (bucket_id in ('papers','gallery') and is_admin());
