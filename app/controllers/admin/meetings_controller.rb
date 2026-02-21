module Admin
  class MeetingsController < BaseController
    def index
      @meetings = Meeting.includes(agenda_versions: { agenda_sections: :agenda_items }).chronological
    end

    def show
      @meeting = Meeting.includes(agenda_versions: { agenda_sections: :agenda_items }).find(params[:id])
      @agenda_version = if params[:version].present?
        @meeting.version(params[:version])
      else
        @meeting.current_version
      end
      @agenda_sections = @agenda_version&.agenda_sections || AgendaSection.none
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
        notice = if service.new_version?
          "New version (v#{service.agenda_version.version_number}) added for this meeting."
        else
          "Meeting agenda imported successfully."
        end
        redirect_to admin_meeting_path(service.meeting), notice: notice
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
