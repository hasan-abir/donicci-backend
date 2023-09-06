namespace :db do
    desc 'Seed the database with initial data'
    task seed: :environment do
        adminRole = Role.find_or_create_by do |role|
            role.name = "ROLE_ADMIN"
            role.save
        end

        User.find_or_create_by do |user|
            user.display_name = "Hasan Abir"
            user.username = "hasan_abir1999"
            user.email = "hasan@test.com"
            user.password = ENV["SUPERUSER_PASSWORD"]
            user.role_ids.push(adminRole._id)
            user.save
        end
    end
end