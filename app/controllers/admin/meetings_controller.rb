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
      unless params[:agenda_file].present? || params[:agenda_url].present?
        flash.now[:alert] = "Please select a file to upload or enter a URL."
        return render :new, status: :unprocessable_entity
      end

      data = if params[:agenda_url].present?
        parse_agenda_url(params[:agenda_url])
      else
        parse_agenda_upload(params[:agenda_file])
      end
      return render :new, status: :unprocessable_entity unless data

      # Check if a meeting already exists for this data — if so, show diff
      meeting_data = data["meeting"]
      existing_meeting = Meeting.find_by(date: meeting_data["date"], meeting_type: meeting_data["type"])

      if existing_meeting&.current_version
        diff_service = AgendaDiffService.new(existing_meeting, data).call
        if diff_service.has_changes?
          cache_key = "agenda_preview_#{existing_meeting.id}_#{SecureRandom.hex(8)}"
          Rails.cache.write(cache_key, data, expires_in: 30.minutes)
          redirect_to preview_agenda_admin_meeting_path(existing_meeting, cache_key: cache_key)
          return
        end
      end

      # No existing meeting or no changes — import normally
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

    def preview_agenda
      @meeting = Meeting.find(params[:id])
      @cache_key = params[:cache_key]
      data = Rails.cache.read(@cache_key)

      unless data
        redirect_to admin_meeting_path(@meeting), alert: "Preview data expired. Please re-upload."
        return
      end

      @diff = AgendaDiffService.new(@meeting, data).call
      unless @diff.has_changes?
        redirect_to admin_meeting_path(@meeting), notice: "No changes detected."
      end
    end

    def apply_agenda
      @meeting = Meeting.find(params[:id])
      cache_key = params[:cache_key]
      data = Rails.cache.read(cache_key)

      unless data
        redirect_to admin_meeting_path(@meeting), alert: "Preview data expired. Please re-upload."
        return
      end

      accepted = params[:accepted] || []
      accepted = accepted.keys if accepted.is_a?(ActionController::Parameters)

      if accepted.empty?
        redirect_to admin_meeting_path(@meeting), notice: "No changes accepted."
        return
      end

      service = AgendaApplyChangesService.new(@meeting, data, accepted).call
      Rails.cache.delete(cache_key)

      if service.success?
        redirect_to admin_meeting_path(@meeting), notice: "#{accepted.size} change(s) applied successfully."
      else
        redirect_to admin_meeting_path(@meeting), alert: service.errors.join(", ")
      end
    end

    def reupload_agenda
      @meeting = Meeting.find(params[:id])
    end

    def import_minutes
      @meeting = Meeting.find(params[:id])

      unless params[:minutes_file].present? || params[:minutes_url].present?
        redirect_to admin_meeting_path(@meeting), alert: "Please select a file to upload or enter a URL."
        return
      end

      data = if params[:minutes_url].present?
        parse_minutes_url(params[:minutes_url])
      else
        parse_minutes_upload(params[:minutes_file])
      end
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

    def auto_tag
      @meeting = Meeting.find(params[:id])
      version = @meeting.current_version
      items = version&.agenda_items&.to_a || []

      AutoTaggingService.new(items).call

      tagged_count = items.count { |i| i.tags.reload.any? }
      redirect_to admin_meeting_path(@meeting),
        notice: "Auto-tagged #{tagged_count} of #{items.size} items."
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

    def parse_agenda_url(url)
      parser = AgendaUrlParserService.new(url)
      data = parser.call
      unless parser.success?
        flash.now[:alert] = parser.errors.join(", ")
        return nil
      end
      data
    end

    def parse_minutes_url(url)
      parser = MinutesUrlParserService.new(url)
      data = parser.call
      unless parser.success?
        @parse_error = parser.errors.join(", ")
        return nil
      end
      data
    end

    def pdf_file?(file)
      file.content_type == "application/pdf" ||
        file.original_filename&.end_with?(".pdf")
    end
  end
end
