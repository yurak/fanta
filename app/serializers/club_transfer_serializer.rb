class ClubTransferSerializer < ActiveModel::Serializer
  attributes :id
  attributes :contract_expires_on
  attributes :loan
  attributes :new_club
  attributes :new_club_name
  attributes :old_club
  attributes :old_club_name
  attributes :start_date

  def new_club
    ClubSerializer.new(object.new_club) if object.new_club
  end

  def old_club
    ClubSerializer.new(object.old_club) if object.old_club
  end
end
