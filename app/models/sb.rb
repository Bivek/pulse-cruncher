class Sb < ActiveRecord::Base

  def timestamp
    read_attribute(:timestamp).to_i
  end
end
