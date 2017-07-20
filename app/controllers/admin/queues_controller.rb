class Admin::QueuesController < AdminController
  def index
    @queues = Resque.queues
  end
end