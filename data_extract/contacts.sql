-- All data from contact subrecords.
-- Contact data from organization and person records is included, as is:

-- * First `termdisplayname` value for the authority term record in which the
--   contact subrecord is nested
-- * End of the URL of the authority term record (you'll need to prepend your
--   instance's URL base to this)

-- .Development history
-- * 2026-04-23
-- ** Target instance runs on a highly customized UI profile.
--    All `addressgroup` fields in this query are custom.

with email as (
  select
    ehier.parentid as contact_db_id,
    string_agg(
      coalesce(deurn(eg.emailtype), '%NULLVALUE%'), '|' order by ehier.pos
    ) as emailtype,
    string_agg(eg.email, '|' order by ehier.pos) as email
  from emailgroup as eg
  inner join hierarchy as ehier on eg.id = ehier.id
  where eg.email is not null
  group by ehier.parentid
),

webaddress as (
  select
    whier.parentid as contact_db_id,
    string_agg(
      coalesce(deurn(wg.webaddresstype), '%NULLVALUE%'), '|' order by whier.pos
    ) as webaddresstype,
    string_agg(wg.webaddress, '|' order by whier.pos) as webaddress
  from webaddressgroup as wg
  inner join hierarchy as whier on wg.id = whier.id
  where wg.webaddress is not null
  group by whier.parentid
),

telephonenumber as (
  select
    hier.parentid as contact_db_id,
    string_agg(
      coalesce(deurn(g.telephonenumbertype), '%NULLVALUE%'),
      '|' order by hier.pos
    ) as telephonenumbertype,
    string_agg(g.telephonenumber, '|' order by hier.pos) as telephonenumber
  from telephonenumbergroup as g
  inner join hierarchy as hier on g.id = hier.id
  where g.telephonenumber is not null
  group by hier.parentid
),

faxnumber as (
  select
    hier.parentid as contact_db_id,
    string_agg(
      coalesce(deurn(g.faxnumbertype), '%NULLVALUE%'), '|' order by hier.pos
    ) as faxnumbertype,
    string_agg(g.faxnumber, '|' order by hier.pos) as faxnumber
  from faxnumbergroup as g
  inner join hierarchy as hier on g.id = hier.id
  where g.faxnumber is not null
  group by hier.parentid
),

address as (
  select
    hier.parentid as contact_db_id,
    string_agg(
      coalesce(deurn(g.addresstypeomca), '%NULLVALUE%'), '|' order by hier.pos
    ) as addresstype,
    string_agg(
      coalesce(g.addressplace1omca, '%NULLVALUE%'), '|' order by hier.pos
    ) as addressplace1,
    string_agg(
      coalesce(g.addressplace2omca, '%NULLVALUE%'), '|' order by hier.pos
    ) as addressplace2,
    string_agg(
      coalesce(g.addressmunicipalityomca, '%NULLVALUE%'), '|' order by hier.pos
    ) as addressmunicipality,
    string_agg(
      coalesce(g.addressstateorprovinceomca, '%NULLVALUE%'),
      '|' order by hier.pos
    ) as addressstateorprovince,
    string_agg(
      coalesce(g.addresspostcodeomca, '%NULLVALUE%'), '|' order by hier.pos
    ) as addresspostcode,
    string_agg(
      coalesce(deurn(g.addresscountryomca), '%NULLVALUE%'),
      '|' order by hier.pos
    ) as addresscountry,
    string_agg(
      coalesce(g.addressnoteomca, '%NULLVALUE%'), '|' order by hier.pos
    ) as addressnote
  from addressgroupomca as g
  inner join hierarchy as hier on g.id = hier.id
  group by hier.parentid
),

base as (
  (
    select
      cc.id as contact_db_id,
      cc.inauthority as authority_csid,
      'organization' as authority_type,
      oc.displayname as authority_subtype,
      cc.initem as term_csid,
      tg.termdisplayname as pref_name,
      cc.displayname as contact_displayname
    from organizations_common as tc
    inner join hierarchy as tchier on tc.id = tchier.id
    inner join contacts_common as cc on tchier.name = cc.initem
    inner join misc on cc.id = misc.id and misc.lifecyclestate != 'deleted'
    inner join hierarchy as ahier on cc.inauthority = ahier.name
    inner join orgauthorities_common as oc on ahier.id = oc.id
    inner join
      hierarchy as termhier
      on
        tc.id = termhier.parentid
        and termhier.primarytype = 'orgTermGroup'
        and termhier.pos = 0
    inner join orgtermgroup as tg on termhier.id = tg.id
  )
  union
  (
    select
      cc.id as contact_db_id,
      cc.inauthority as authority_csid,
      'person' as authority_type,
      oc.displayname as authority_subtype,
      cc.initem as term_csid,
      tg.termdisplayname as pref_name,
      cc.displayname as contact_displayname
    from persons_common as tc
    inner join hierarchy as tchier on tc.id = tchier.id
    inner join contacts_common as cc on tchier.name = cc.initem
    inner join misc on cc.id = misc.id and misc.lifecyclestate != 'deleted'
    inner join hierarchy as ahier on cc.inauthority = ahier.name
    inner join personauthorities_common as oc on ahier.id = oc.id
    inner join
      hierarchy as termhier
      on
        tc.id = termhier.parentid
        and termhier.primarytype = 'personTermGroup'
        and termhier.pos = 0
    inner join persontermgroup as tg on termhier.id = tg.id
  )
)

select
  base.contact_db_id,
  base.authority_type,
  base.authority_subtype,
  base.pref_name,
  base.contact_displayname,
  email.email,
  email.emailtype,
  web.webaddress,
  web.webaddresstype,
  ph.telephonenumber,
  ph.telephonenumbertype,
  fax.faxnumber,
  fax.faxnumbertype,
  addr.addresstype,
  addr.addressplace1,
  addr.addressplace2,
  addr.addressmunicipality,
  addr.addressstateorprovince,
  addr.addresspostcode,
  addr.addresscountry,
  addr.addressnote,
  concat('/record/all/', base.term_csid) as term_rec_url
from base
left join email on base.contact_db_id = email.contact_db_id
left join webaddress as web on base.contact_db_id = web.contact_db_id
left join telephonenumber as ph on base.contact_db_id = ph.contact_db_id
left join faxnumber as fax on base.contact_db_id = fax.contact_db_id
left join address as addr on base.contact_db_id = addr.contact_db_id
