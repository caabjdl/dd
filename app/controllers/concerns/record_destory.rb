module RecordDestory
  extend ActiveSupport::Concern

  def destroy
    model = controller_name.classify.constantize.find(params[:id])
    model.is_delete = true
    model.save
    redirect_to 'index'
  end
end