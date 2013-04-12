require "json"

class AnnotationsController < ApplicationController
  
  def show
    
    @annotations=Annotation.where(:druid=>params[:id])
    @annotations.each do |annotation| # loop through all annotations
      annotation_hash=JSON.parse(annotation.annotation) # parse the annotation json into a ruby object
      annotation_hash[:editable]=(annotation.user_id==current_user.id) # the annotation is editable if it belongs to the logged in user
      annotation_hash[:username]=(annotation.user_id==current_user.id ? "me" : annotation.user.to_s) # add the username (or "me" if current user)
      annotation_hash[:updated_at]=annotation.updated_at.strftime('%B %d, %Y')
      annotation_hash[:id]=annotation.id
      annotation.annotation=annotation_hash.to_json # convert back to json
    end
    
    respond_to do |format|
      format.xml  { render :xml => @annotations.to_xml }
      format.json { render :json=> @annotations.to_json }
    end
    
  end
  
  def create
    
    annotation_json=params[:annotation]
    annotation_hash=JSON.parse(annotation_json)
    @annotation=Annotation.create(:annotation=>annotation_json,:annotation_text=>annotation_hash['text'],:druid=>params[:druid],:user_id=>current_user.id)

    respond_to do |format|
      format.xml  { render :xml => @annotation.to_xml }
      format.json { render :json=> @annotation.to_json }
    end
    
  end
  
  def update 
  
    annotation_json=params[:annotation]
    annotation_hash=JSON.parse(annotation_json)
    
    @annotation=Annotation.find(params[:id])
    @annotation.annotation=annotation_json
    @annotation.annotation_text=annotation_hash['text']
    @annotation.save

    respond_to do |format|
      format.xml  { render :xml => @annotation.to_xml }
      format.json { render :json=> @annotation.to_json }
    end
           
  end
  
end
