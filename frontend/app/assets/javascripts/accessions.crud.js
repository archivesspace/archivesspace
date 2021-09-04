//= require tree
//= require resources.crud
//= require lang_materials.crud
//= require dates.crud
//= require agents.crud
//= require subjects.crud
//= require deaccessions.crud
//= require subrecord.crud
//= require rights_statements.crud
//= require form
//= require transfer_dropdown
//= require add_event_dropdown
//= require collection_management_records.crud
//= require interrelated_accessions.crud
//= require slug

$(function () {
  $(document).triggerHandler("loadedrecordform.aspace", [$("#form_accession")]);
});
