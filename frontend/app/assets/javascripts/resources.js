//= require plugins/jstree


$(function() {
   // init the archives tree
   $(".archives-tree").jstree({
       "plugins": ["themes","json_data","ui","crrm","cookies","dnd","search","types","hotkeys","contextmenu"]       
   })	
});