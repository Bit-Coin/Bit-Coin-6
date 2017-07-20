class Admin::EventsController < AdminController
  def system_events
    @events = SystemEvent.all
  end
end
