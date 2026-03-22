module Admin
  class EmailCampaignsController < BaseController
    before_action :set_campaign, only: %i[show edit update destroy send_campaign preview]
    rate_limit to: 3, within: 1.minute, only: :send_campaign, with: -> { redirect_to admin_email_campaign_path(@campaign), alert: "Too many requests. Please wait a moment." }

    def index
      @campaigns = EmailCampaign.includes(:user).chronological
    end

    def show
      @sent_count = @campaign.email_deliveries.sent.count
      @pending_count = @campaign.email_deliveries.pending.count
      @failed_count = @campaign.email_deliveries.failed.count
    end

    def new
      @campaign = EmailCampaign.new
    end

    def create
      @campaign = EmailCampaign.new(campaign_params)
      @campaign.user = Current.user

      if @campaign.save
        audit("email_campaign.create", target: @campaign)
        redirect_to admin_email_campaign_path(@campaign), notice: "Campaign created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      unless @campaign.draft?
        redirect_to admin_email_campaign_path(@campaign), alert: "Cannot edit a sent campaign."
      end
    end

    def update
      unless @campaign.draft?
        redirect_to admin_email_campaign_path(@campaign), alert: "Cannot edit a sent campaign."
        return
      end

      if @campaign.update(campaign_params)
        redirect_to admin_email_campaign_path(@campaign), notice: "Campaign updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      unless @campaign.draft?
        redirect_to admin_email_campaign_path(@campaign), alert: "Cannot delete a sent campaign."
        return
      end

      audit("email_campaign.destroy", target: @campaign, metadata: { title: @campaign.title })
      @campaign.destroy!
      redirect_to admin_email_campaigns_path, notice: "Campaign deleted."
    end

    def preview
    end

    def send_campaign
      unless @campaign.draft?
        redirect_to admin_email_campaign_path(@campaign), alert: "Campaign already sent."
        return
      end

      @campaign.send_campaign!
      audit("email_campaign.send", target: @campaign, metadata: { recipient_count: @campaign.recipient_count })
      redirect_to admin_email_campaign_path(@campaign), notice: "Campaign is being sent to #{@campaign.recipient_count} recipients."
    end

    private

    def set_campaign
      @campaign = EmailCampaign.find(params[:id])
    end

    def campaign_params
      params.expect(email_campaign: [ :title, :body, :campaign_type ])
    end
  end
end
