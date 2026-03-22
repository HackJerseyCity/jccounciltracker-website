module Admin
  class InvitationsController < BaseController
    before_action :require_site_admin, only: [ :new, :create, :destroy ]

    def index
      @pending_invitations = Invitation.pending.includes(:invited_by).order(created_at: :desc)
      @accepted_invitations = Invitation.accepted.includes(:invited_by, :accepted_by).order(accepted_at: :desc)
    end

    def new
      @invitation = Invitation.new(role: :content_admin)
    end

    def create
      @invitation = Invitation.new(invitation_params)
      @invitation.invited_by = Current.session.user

      if @invitation.save
        audit("invitation.create", target: @invitation, metadata: { role: @invitation.role })
        redirect_to admin_invitations_path, notice: "Invitation created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @invitation = Invitation.find(params[:id])
      audit("invitation.revoke", target: @invitation)
      @invitation.destroy
      redirect_to admin_invitations_path, notice: "Invitation revoked."
    end

    private

    def invitation_params
      params.expect(invitation: [ :role ])
    end
  end
end
