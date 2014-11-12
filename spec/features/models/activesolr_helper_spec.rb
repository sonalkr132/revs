require "spec_helper"

describe ActivesolrHelper, :integration => true do
  
  describe "class level methods" do 
     
    it "find method should return an instance of a solr document that is an item" do
      doc = SolrDocument.find('yt907db4998')
      doc.should be_a SolrDocument
      doc.title.should == 'Record 1'
      doc.is_item?.should be_true
    end
  
    it "should have the correct mvf field marker" do
      SolrDocument.multivalued_field_marker.should == '_mvf'
    end
  
    it "should indicate when values are equivalent, whether arrays of regardless of type or extra leading/trailing spaces" do
      SolrDocument.is_equal?(1,"1").should be_true
      SolrDocument.is_equal?("1","1").should be_true
      SolrDocument.is_equal?(["1"],"1").should be_true
      SolrDocument.is_equal?(["1"],1).should be_true
      SolrDocument.is_equal?(["abc"],"abc").should be_true
      SolrDocument.is_equal?("abc",["abc"]).should be_true
      SolrDocument.is_equal?("abc",["abc","123"]).should be_false
      SolrDocument.is_equal?([123,"abc"],["abc","123"]).should be_true
      SolrDocument.is_equal?([123,"  abc"],["abc","123 "]).should be_true
    end

    it "should indicate when multivalued field values are equivalent to the solr field array equivalents" do
       SolrDocument.is_equal?("1",1,true).should be_true
       SolrDocument.is_equal?("1","1",true).should be_true
       SolrDocument.is_equal?(1,"1",true).should be_true
       SolrDocument.is_equal?([1],"1",true).should be_true
       SolrDocument.is_equal?([1,2],"1 | 2",true).should be_true
       SolrDocument.is_equal?(['1','2'],"1 | 2",true).should be_true
       SolrDocument.is_equal?(['peter','paul','mary']," peter |  paul| mary",true).should be_true
       SolrDocument.is_equal?(['peter','paul','mary'],"peter|paul|mary",true).should be_true
       SolrDocument.is_equal?(['peter','paul','mary'],"peter|paul|mary",false).should be_false # if we don't ask for a multivalued field comparison, this should fail

       SolrDocument.is_equal?(['1','2'],["1 | 2"],true).should be_false # an incoming array is not what you'd expect coming from a multivalued field

     end
    
    it "to_array should convert strings to arrays, and leave arrays alone" do
      SolrDocument.to_array('test').should == ['test']
      SolrDocument.to_array(1).should == [1]
      SolrDocument.to_array('').should == ['']
      SolrDocument.to_array(nil).should == [nil]
      SolrDocument.to_array([]).should == []
      SolrDocument.to_array(['test']).should == ['test']
      SolrDocument.to_array(['test','test2']).should == ['test','test2']
    end
  
    it "should return if a value is blank, either an array of blank entries or a single blank value" do
      SolrDocument.blank_value?(nil).should be_true
      SolrDocument.blank_value?([nil]).should be_true
      SolrDocument.blank_value?(['']).should be_true
      SolrDocument.blank_value?(['','']).should be_true
      SolrDocument.blank_value?('a').should be_false
      SolrDocument.blank_value?(['a']).should be_false    
      SolrDocument.blank_value?(['a','']).should be_false    
      SolrDocument.blank_value?(['a',nil]).should be_false    
    end
  
  end

  describe "getter methods" do
    
    it "should fail with a non-configured getter" do
      doc = SolrDocument.find('jg267fg4283')
      expect { value=doc.bogus_field }.to raise_error
    end
    
    it "should retrieve a couple single valued fields correctly" do
      doc = SolrDocument.find('yh093pt9555')
      doc.title.should == doc['title_tsi']
      doc.title.class.should == String
      doc.photographer.should == doc['photographer_ssi']
      doc.photographer.class.should == String
      doc.description.should == doc['description_tsim'].first # returns a single value even though this is a multivalued field in solr
      doc.description.class.should == String
    end

    it "should retrieve a couple multivalued fields correctly" do
      doc = SolrDocument.find('yh093pt9555')
      doc.marque.should == doc['marque_ssim']
      doc.marque.class.should == Array
      doc.people.should == doc['people_ssim']
      doc.people.class.should == Array
    end

    it "should retrieve a couple a multivalued fields correctly with a split when using the MFV syntax" do
      doc = SolrDocument.find('yh093pt9555')
      doc.marque_mvf.should == doc['marque_ssim'].join(' | ')
      doc.marque_mvf.class.should == String
    end
              
    it "should return an empty string when that value doesn't exist in the solr doc" do
      doc = SolrDocument.find('yt907db4998')
      doc['photographer_ssi'].should be_nil
      doc['model_year_ssim'].should be_nil
      doc.photographer.should == ""
      doc.model_year.should == ""
    end
    
    it "should return the default value for the title when it is not set" do
      doc = SolrDocument.find('jg267fg4283')
      doc['title_tsi'].should be_nil
      doc.title.should == 'Untitled'
      doc['title_tsi']='' # even when blank, it should still show as untitled
      doc.title.should == 'Untitled'
    end
    
  end
  
  describe "setter methods" do
    
    it "should fail with a non-configured setter" do
      doc = SolrDocument.find('jg267fg4283')
      expect { doc.bogus_field="dude" }.to raise_error
    end
    
    it "should update the value of a single valued field" do
      new_value="cool new title"
      doc = SolrDocument.find('jg267fg4283')
      doc['title_tsi'].should be_nil
      doc.title=new_value
      doc['title_tsi']=new_value # solr field was updated
      doc.title.should == new_value
    end

    it "should update the value of a multivalued field directly" do
      new_value=['Jaguar','Porsche']
      doc = SolrDocument.find('yh093pt9555')
      doc.marque.should_not == new_value
      doc.marque=new_value
      doc['marque_ssim']=new_value # solr field was updated
      doc.marque.should == new_value
    end 

    it "should update the value of a multivalued field via the special MVF syntax, leave extra spaces" do
      new_value=' Jaguar |  Porsche'
      new_value_as_array=[' Jaguar ','  Porsche']
      doc = SolrDocument.find('yh093pt9555')
      doc.marque.should_not == new_value_as_array
      doc.marque_mvf.should_not == new_value
      doc.marque_mvf=new_value
      doc['marque_ssim']=new_value_as_array # solr field was updated
      doc.marque.should == new_value_as_array
      doc.marque.class.should == Array
      doc.marque_mvf.should == new_value_as_array.join(' | ')
      doc.marque_mvf.class.should == String
    end
           
  end
  
  describe "saving" do

    before :each do
      @druid='yt907db4998'
      @doc = SolrDocument.find(@druid)
    end
    
    after :each do
      reindex_solr_docs(@druid)
      cleanup_editstore_changes # transactions don't seem to work with the second database
    end    
    
    it "should save an update to a single value field, and propogage to solr and editstore databases" do
      
      Editstore::Change.count.should == 0
    
      new_value='Test changed it' 
      old_value=@doc.title
      @doc.title.should_not == new_value # update the title
      @doc.title=new_value
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      reload_doc.title.should == new_value
      
       # confirm we have a new change in the database
      last_edit=Editstore::Change.last
      editstore_entry(Editstore::Change.last,:field=>'title_tsi',:new_value=>new_value,:old_value=>old_value,:druid=>@druid,:operation=>'update',:state=>:ready).should be_true
      Editstore::Change.count.should == 1
      
    end

    it "should save an update to a single value field, and propogage to solr but not to editstore database if not configured to do that" do
      
      # the priority field is configured to not propogate to editstore
      
      Editstore::Change.count.should == 0
    
      new_value='2' 
      old_value=@doc.priority
      @doc.priority.should_not == new_value
      @doc.priority=new_value
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      reload_doc.priority.should == new_value.to_i
      
       # confirm we don't have a new change in the database
      Editstore::Change.count.should == 0
      
    end

    it "should save an update to a single value field with special odd characters, and propogage to solr and editstore databases" do
      
      Editstore::Change.count.should == 0
    
      new_value="Test changed it, including apostraphe ' and slahses \\  /  and a quote \" and a pipe |  this not a multivalued field, should be fine " 
      old_value=@doc.title
      @doc.title.should_not == new_value # update the title
      @doc.title=new_value
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      reload_doc.title.should == new_value.strip
      
       # confirm we have a new change in the database
      editstore_entry(Editstore::Change.last,:field=>'title_tsi',:new_value=>new_value.strip,:old_value=>old_value,:druid=>@druid,:operation=>'update',:state=>:ready).should be_true
      Editstore::Change.count.should == 1

    end
    
    it "should save a new entry to a single value field, and propogage to solr and editstore databases" do
      
      Editstore::Change.count.should == 0
    
      new_value='Patrick Starfish' 
      @doc.photographer.should == ""
      @doc.photographer=new_value
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      reload_doc.photographer.should == new_value
      
       # confirm we have a new change in the database
      editstore_entry(Editstore::Change.last,:field=>'photographer_ssi',:new_value=>new_value,:old_value=>nil,:druid=>@druid,:operation=>'create',:state=>:ready).should be_true
      Editstore::Change.count.should == 1
      
    end

    it "should clear out an existing entry to a single value field, and propogage to solr and editstore databases" do
      
      Editstore::Change.count.should == 0
    
      @doc.entrant.should == ["Fastguy, Some"]
      @doc.entrant=""
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      reload_doc.entrant.should == ""
      
       # confirm we have a new change in the database
      editstore_entry(Editstore::Change.last,:field=>'entrant_ssim',:new_value=>'',:old_value=>nil,:druid=>@druid,:operation=>'delete',:state=>:ready).should be_true
      Editstore::Change.count.should == 1
      
    end

    it "should clear out an existing entry to a mutlivalued field, and propogage to solr and editstore databases" do
      
      Editstore::Change.count.should == 0
    
      # current value
      @doc.vehicle_model.should == ['Mystique','328i']

      # clear out values
      @doc.vehicle_model_mvf=''
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      reload_doc.vehicle_model.should == ""
      
       # confirm we have a new change in the database
      editstore_entry(Editstore::Change.last,:field=>'model_ssim',:new_value=>'',:old_value=>nil,:druid=>@druid,:operation=>'delete',:state=>:ready).should be_true
      Editstore::Change.count.should == 1
      
    end
    
    it "should save a new entry to a multivalue field using MVF syntax, and propogage to solr and editstore databases, stripping extra spaces" do
      
      Editstore::Change.count.should == 0
      new_values=' Ferrari |  Tesla '  
      new_values_as_array=['Ferrari','Tesla']
      
      # currently blank
      @doc.marque.should == ""
      
      # set new values
      @doc.marque_mvf=new_values
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      reload_doc.marque.should == new_values_as_array
      reload_doc.marque_mvf.should == new_values_as_array.join(' | ')
      
       # confirm we have new changes in the database
      last_edits=Editstore::Change.all
      editstore_entry(last_edits[0],:field=>'marque_ssim',:new_value=>new_values_as_array[0],:old_value=>nil,:druid=>@druid,:operation=>'create',:state=>:ready).should be_true
      editstore_entry(last_edits[1],:field=>'marque_ssim',:new_value=>new_values_as_array[1],:old_value=>nil,:druid=>@druid,:operation=>'create',:state=>:ready).should be_true 
      Editstore::Change.count.should == 2
      
    end

    it "shouldn't add anything to the Editstore database if nothing is changed, even is save is called" do
      
      Editstore::Change.count.should == 0
      saved=@doc.save
      saved.should be_true
      Editstore::Change.count.should == 0
      
    end

    it "shouldn't add anything to the Editstore database when some fields do not actually change, even is save is called" do
      
      Editstore::Change.count.should == 0
      @doc.title = @doc[:title_tsi]
      @doc.years_mvf = @doc[:pub_year_isim].join(" | ")
      saved=@doc.save
      saved.should be_true
      Editstore::Change.count.should == 0
      
    end

    it "shouldn't add anything to the Editstore database or update solr and save nothing when there is an invalid value" do
      
      Editstore::Change.count.should == 0
      @doc.full_date.should == ''
      @doc.full_date='bogusness'
      @doc.valid?.should be_false
      saved=@doc.save
      saved.should be_false
      reload_doc=SolrDocument.find(@druid)
      reload_doc.full_date.should == ''
      Editstore::Change.count.should == 0
      
    end
    
    it "should save an updated entry to a multivalue field using MVF syntax, and propogage to solr and editstore databases, stripping extra spaces" do
      
      Editstore::Change.count.should == 0
      new_values=' Contour |128i '  
      new_values_as_array=['Contour','128i']
      
      # current values
      @doc.vehicle_model.should == ['Mystique','328i']

      # set new value
      @doc.vehicle_model_mvf=new_values
      @doc.save

      # refetch doc from solr and confirm new value was saved
      reload_doc = SolrDocument.find(@druid)
      reload_doc.vehicle_model.should == new_values_as_array
      reload_doc.vehicle_model_mvf.should == new_values_as_array.join(' | ')
      
       # confirm we have new changes in the database, which includes a delete and two adds
      last_edits=Editstore::Change.all
      editstore_entry(last_edits[0],:field=>'model_ssim',:new_value=>'',:old_value=>nil,:druid=>@druid,:operation=>'delete',:state=>:ready).should be_true
      editstore_entry(last_edits[1],:field=>'model_ssim',:new_value=>new_values_as_array[0],:old_value=>nil,:druid=>@druid,:operation=>'create',:state=>:ready).should be_true
      editstore_entry(last_edits[2],:field=>'model_ssim',:new_value=>new_values_as_array[1],:old_value=>nil,:druid=>@druid,:operation=>'create',:state=>:ready).should be_true
      Editstore::Change.count.should == 3
      
    end

  end
  
  describe "cached edits" do
  
    before :each do
      @doc = SolrDocument.find('yt907db4998')
    end
    
    it "should not have any unsaved edits when initialized" do
      unchanged(@doc).should be_true
    end

    it "should indicate when a change has occurred to a field, but not saved" do
      Editstore::Change.count.should == 0
      new_value="new title!"
      old_value=@doc.title
      unchanged(@doc).should be_true
      @doc.title=new_value
      changed(@doc,{:title_tsi=>new_value}).should be_true
      @doc.title.should == new_value # change is in memory
      reload_doc = SolrDocument.find('yt907db4998') # change is not saved to solr or editstore though
      reload_doc.title.should == old_value 
      Editstore::Change.count.should == 0
    end

    it "should not cache an edit when a single valued field is set but hasn't actually changed" do
      Editstore::Change.count.should == 0
      old_value=@doc.title
      unchanged(@doc).should be_true
      @doc.title=old_value
      unchanged(@doc).should be_true      
      Editstore::Change.count.should == 0
    end

    it "should not cache an edit when a mutivalued field with one value is set but hasn't actually changed" do
      Editstore::Change.count.should == 0
      @doc.years.should == [1960] # its an array with an integer value
      unchanged(@doc).should be_true
      @doc.years="1960" # set to a single valued string, but it should be equivalent and not marked as a change
      unchanged(@doc).should be_true
      @doc.years_mvf="1960" # now set the equivalent _mvf field, but it should be equivalent and not marked as a change
      unchanged(@doc).should be_true    
      Editstore::Change.count.should == 0
    end

    it "should not cache an edit when a mutivalued field with two values is set but hasn't actually changed" do
      doc2=SolrDocument.find('yh093pt9555')
      Editstore::Change.count.should == 0
      doc2.years.should == [1955,1956] # its an array with integer value2
      unchanged(doc2).should be_true
      doc2.years=[1955,1956] # set to an equivalent array
      unchanged(doc2).should be_true
      doc2.years=["1955","1956"] # set to an equivalent array but of string
      unchanged(doc2).should be_true
      doc2.years_mvf="1955 | 1956" # now set the equivalent _mvf field like it would be coming from the form
      unchanged(doc2).should be_true
      Editstore::Change.count.should == 0
    end
    
    it "should cache an edit when a mutivalued field is set and has changed" do
      Editstore::Change.count.should == 0
      old_value=[1960]
      @doc.years.should == old_value # its an array with an integer value
      unchanged(@doc).should be_true
      @doc.years="1961"
      changed(@doc,{:pub_year_isim=>'1961'}).should be_true
      reload_doc = SolrDocument.find('yt907db4998') # change is not saved to solr or editstore though
      reload_doc.years.should == old_value    
      Editstore::Change.count.should == 0  # no changes to Editstore yet
    end

    it "should cache an edit when a mutivalued field is set using the special MVF syntax and has changed" do
      Editstore::Change.count.should == 0
      old_value=[1960]
      @doc.years.should == old_value # its an array with an integer value
      unchanged(@doc).should be_true
      @doc.years_mvf="1961|1962"
      @doc.years=['1961','1962'] # should return as an array
      changed(@doc,{:pub_year_isim=>['1961','1962']}).should be_true
      reload_doc = SolrDocument.find('yt907db4998') # change is not saved to solr or editstore though
      reload_doc.years.should == old_value    
      Editstore::Change.count.should == 0  # no changes to Editstore yet
    end

  end
  
end