module Admin
  class MeetingsController < BaseController
    def index
      @meetings = Meeting.includes(agenda_versions: { agenda_sections: :agenda_items }).chronological
    end

    def show
      @meeting = Meeting.includes(agenda_versions: { agenda_sections: { agenda_items: :tags } }).find(params[:id])
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
        flash.now[:alert] = "Please select a file to upload."
        return render :new, status: :unprocessable_entity
      end

      data = parse_agenda_upload(params[:agenda_file])
      return render :new, status: :unprocessable_entity unless data

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
    end

    def import_minutes
      @meeting = Meeting.find(params[:id])

      unless params[:minutes_file].present?
        redirect_to admin_meeting_path(@meeting), alert: "Please select a file to upload."
        return
      end

      data = parse_minutes_upload(params[:minutes_file])
      unless data
        redirect_to admin_meeting_path(@meeting), alert: @parse_error
        return
      end

      service = MinutesImportService.new(data).call

      if service.success?
        notice = "Minutes imported successfully."
        notice += " Warnings: #{service.warnings.join('; ')}" if service.warnings.any?
        redirect_to admin_meeting_path(@meeting), notice: notice
      else
        redirect_to admin_meeting_path(@meeting), alert: service.errors.join(", ")
      end
    end

    def delete_minutes
      @meeting = Meeting.find(params[:id])

      ActiveRecord::Base.transaction do
        @meeting.agenda_items.each do |item|
          item.votes.delete_all
          item.update!(result: nil, vote_tally: nil)
        end
      end

      redirect_to admin_meeting_path(@meeting), notice: "Minutes data deleted."
    end

    def publish
      @meeting = Meeting.find(params[:id])
      @agenda_version = @meeting.agenda_versions.find(params[:version_id])
      if @agenda_version.published?
        @agenda_version.unpublish!
        redirect_to admin_meeting_path(@meeting), notice: "Version #{@agenda_version.version_number} unpublished."
      else
        @agenda_version.publish!
        redirect_to admin_meeting_path(@meeting), notice: "Version #{@agenda_version.version_number} published."
      end
    end

    def destroy
      @meeting = Meeting.find(params[:id])
      @meeting.destroy!
      redirect_to admin_meetings_path, notice: "Meeting deleted."
    end

    private

    def parse_agenda_upload(file)
      if pdf_file?(file)
        parser = AgendaPdfParserService.new(file.tempfile)
        data = parser.call
        unless parser.success?
          flash.now[:alert] = parser.errors.join(", ")
          return nil
        end
        data
      else
        JSON.parse(file.read)
      end
    rescue JSON::ParserError
      flash.now[:alert] = "Invalid JSON file."
      nil
    end

    def parse_minutes_upload(file)
      if pdf_file?(file)
        parser = MinutesPdfParserService.new(file.tempfile)
        data = parser.call
        unless parser.success?
          @parse_error = parser.errors.join(", ")
          return nil
        end
        data
      else
        JSON.parse(file.read)
      end
    rescue JSON::ParserError
      @parse_error = "Invalid JSON file."
      nil
    end

    def pdf_file?(file)
      file.content_type == "application/pdf" ||
        file.original_filename&.end_with?(".pdf")
    end
  end
end
