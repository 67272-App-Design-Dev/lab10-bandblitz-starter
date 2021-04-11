class Band < ApplicationRecord
	attr_accessor :genre_ids
  
  # relationships
  has_many :band_genres
  has_many :genres, :through => :band_genres
  has_many :users
  # has_many :comments, :dependent => :destroy

  # uploaders
  mount_uploader :photo, PhotoUploader
  mount_uploader :song, SongUploader

  # scopes
  scope :alphabetical, -> { order('name') }
  
  # basic validation
  validates_presence_of :name, :description
  validate :at_least_one_genre_chosen

  # callbacks
  before_validation :process_genres
  after_save :adjust_saved_genres
  
  private

  def at_least_one_genre_chosen
    if @genre_ids.empty?
      self.errors.add(:base, "Choose as least one valid genre")
      return false
    end
    return true
  end

  def process_genres

    # ensure it is not nill
    if @genre_ids.nil?
      @genre_ids = []
    end

    # convert to ints
    @genre_ids = @genre_ids.map {|gid| gid.to_i}

    # filter out the ones that don't exist
    @genre_ids = @genre_ids & ((Genre.all.map {|g| g.id} ).to_a)
  end

  def adjust_saved_genres
    current_genres = BandGenre.all.filter {|bg| bg.band_id == self.id} # note that @id is not set yet but self.id is...
    removed_genres = current_genres.reject {|g| @genre_ids.include? g.genre_id}
    added_genres = @genre_ids.reject {|gid| current_genres.any? {|g| g.genre_id == gid}}.map {|gid| BandGenre.new band_id: self.id, genre_id: gid}
    removed_genres.each do |g|
      unless g.destroy
        self.errors.add(:base, "failed to remove the genre #{g.genre.name}")
        throw(:abort)
      end
    end
    added_genres.each do |g|
      unless g.save
        byebug
        self.errors.add(:base, "failed to add the genre #{g.genre.name}")
        throw(:abort)
      end
    end
  end
  
end
