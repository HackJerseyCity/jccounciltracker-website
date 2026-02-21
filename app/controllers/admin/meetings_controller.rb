module Admin
  class MeetingsController < BaseController
    def index
      @meetings = Meeting.chronological
    end

    def show
      @meeting = Meeting.includes(agenda_sections: :agenda_items).find(params[:id])
    end

    def new
    end

    def create
      unless params[:agenda_file].present?
        flash.now[:alert] = "Please select a JSON file to upload."
        return render :new, status: :unprocessable_entity
      end

      data = JSON.parse(params[:agenda_file].read)
      service = AgendaImportService.new(data).call

      if service.success?
        redirect_to admin_meeting_path(service.meeting), notice: "Meeting agenda imported successfully."
      else
        flash.now[:alert] = service.errors.join(", ")
        render :new, status: :unprocessable_entity
      end
    rescue JSON::ParserError
      flash.now[:alert] = "Invalid JSON file."
      render :new, status: :unprocessable_entity
    end

    def destroy
      @meeting = Meeting.find(params[:id])
      @meeting.destroy!
      redirect_to admin_meetings_path, notice: "Meeting deleted."
    end
  end
end
