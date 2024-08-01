class CreateCountries < ActiveRecord::Migration::Current
  def change
    create_table :countries do |t|
      t.column :name, :string
    end
  end
end
