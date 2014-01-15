class SavedItem < ActiveRecord::Base
  
  belongs_to :gallery
  
  attr_accessible :druid, :gallery_id, :description
  
  validates :gallery_id, :numericality => { :only_integer => true }
  validates :druid, :is_druid=>true
  validate :only_one_favorite_per_user_per_druid
  
  def self.save_favorite(params={})
    user_id=params[:user_id]
    druid=params[:druid]
    description=params[:description]
    gallery=Gallery.get_favorites_list(user_id) # creates the default favorites list if it does not exist
    return self.create(:druid=>druid,:gallery_id=>gallery.id,:description=>description)
  end
  
  def only_one_favorite_per_user_per_druid
    errors.add(:druid, :cannot_be_more_than_one_favorite_per_user_per_druid) if self.class.where(:druid=>self.druid,:gallery_id=>self.gallery_id).size != 0
  end
  
end