class Trip < ApplicationRecord
    require 'csv'

    def self.import(file)
        CSV.foreach(file.path, headers: true) do |row|
            Trip.create! row.to_hash
        end
    end            

    def self.search_user(user_id)
        if user_id
            where('user_id = ?', user_id)
        # else
        #     all
        end
    end
end
