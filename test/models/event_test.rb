require 'test_helper'

class EventTest < ActiveSupport::TestCase

  it 'does not allow unknown severity' do
    event = Event.create({severity: 'blarp'})
    assert event.errors.any?
  end

  it 'requires a name' do
    event = Event.create({})
    assert event.errors.any?
  end

end
