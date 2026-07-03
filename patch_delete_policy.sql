-- =========================================================
-- PATCH for project qmjsfshhnwjtdmraatcv
-- Run this if you already ran the ORIGINAL setup script.
-- Safe to run multiple times. Does NOT duplicate any data.
-- =========================================================

-- 1. Allow file deletion from the attachments bucket (needed by the 🗑️ button on files)
drop policy if exists anon_delete_attachments on storage.objects;
create policy anon_delete_attachments on storage.objects
  for delete to anon, authenticated using (bucket_id = 'attachments');

-- 2. Optional but recommended: rewrite ACT-01 / ACT-02 descriptions as point-wise notes
update actionables set description = E'Track every recurring bill for all FETS locations — internet, phone, electricity, rent, DG, water, waste removal.\nCovers Cochin centre, Calicut centre and the Calicut office guest house.\nPhase 1: internet & telephone details. Electricity comes in the next phase.'
where code = 'ACT-01';

update actionables set description = E'One master registry for every exam client — Pearson VUE, ACCA, CELPIP, PSI and more.\nPer client: site codes, certified staff, installed software, support desk and contact persons.\nPlus exams delivered, login/technical requirements and client-specific procedures.'
where code = 'ACT-02';
