# frozen_string_literal: true

class CreateSlotsSessions < ActiveRecord::Migration[5.2]
  def change
    create_table :slots_jwt_sessions do |t|
      t.string :session, length: 128
      t.bigint :jwt_iat
      t.bigint :previous_jwt_iat
      t.bigint :user_id, index: true

      t.timestamps
    end
    add_index :slots_jwt_sessions, :session, unique: true
  end
end
