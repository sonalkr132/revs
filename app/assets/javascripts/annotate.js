anno.addHandler('onAnnotationCreated', function(annotation) {
	annotation.username='me';
	annotation.updated_at='today';
	jQuery.ajax({
		type: "POST",
		url: "/annotations",
		dataType: "JSON",
		data: "annotation="+JSON.stringify(annotation)+"&druid=" + jQuery("#druid").attr('data-druid'),
		success: function(data) {
	    annotation.id=data.id; // the annotation ID should match the database row ID
	  }
		});
});

anno.addHandler('onAnnotationUpdated', function(annotation) {
	jQuery.ajax({
	  type: "PUT",
		dataType: "JSON",
	  url: "/annotations/" + annotation.id,
	  data: "annotation="+JSON.stringify(annotation)
	});
});

annotorious.plugin.addUsernamePlugin = function(opt_config_options) { }

annotorious.plugin.addUsernamePlugin.prototype.onInitAnnotator = function(annotator) {
  // A Field can be an HTML string or a function(annotation) that returns a string
  annotator.popup.addField(function(annotation) { 
    return '<em>from ' + annotation.username + ' - '+ annotation.updated_at +'</em>'
  });
}

anno.addPlugin('addUsernamePlugin', {});	

function showAnnotations() {	
	togglePURLEmbed();
	toggleThumbImage();
	enableAnnotations();
	loadAnnotations();
}

function hideAnnotations() {
	togglePURLEmbed();
	toggleThumbImage();
}
	 
function enableAnnotations() {
	anno.makeAnnotatable(jQuery('#annotatable_image')[0]);	
}

function loadAnnotations() {
	jQuery.getJSON("/annotations/"+jQuery("#druid").attr('data-druid') + ".json",function(data) {
		for (var i = 0; i < data.length; i++) {
				annotation=JSON.parse(data[i].json)
        anno.addAnnotation(annotation);
			}
	});
}

function togglePURLEmbed() {
	jQuery('#image_workspace').toggleClass('hidden');	
}

function toggleThumbImage() {
	jQuery('#annotatable_workspace').toggleClass('hidden');	
}

function disableNewAnnotations() {
	anno.setSelectionEnabled(false);	
}

function toggleLinks() {
 $('.annotation_links').toggleClass('hidden');
 $('#hide_annotations_link').toggleClass('hidden');
}

$(document).ready(function(){
	
	$('#annotate_link').click(function() { 
		showAnnotations(); 
    toggleLinks();
		return false;
	 });
	
	$('#view_annotations_link').click(function() {
		 showAnnotations(); 
		 disableNewAnnotations(); 
		 toggleLinks();
		 return false;
	 });

	$('#hide_annotations_link').click(function() {
		 hideAnnotations(); 
		 toggleLinks();
		 return false;
	 });
	
});