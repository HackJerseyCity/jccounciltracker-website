module Admin
  class CouncilMembersController < BaseController
    def index
      @current_members = CouncilMember.current.alphabetical
      @past_members = CouncilMember.where.not(id: @current_members.select(:id)).alphabetical
    end

    def new
      @council_member = CouncilMember.new
    end

    def create
      @council_member = CouncilMember.new(council_member_params)

      if @council_member.save
        audit("council_member.create", target: @council_member)
        redirect_to admin_council_members_path, notice: "Council member added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @council_member = CouncilMember.find(params[:id])
    end

    def update
      @council_member = CouncilMember.find(params[:id])

      if @council_member.update(council_member_params)
        audit("council_member.update", target: @council_member)
        redirect_to admin_council_members_path, notice: "Council member updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @council_member = CouncilMember.find(params[:id])
      audit("council_member.destroy", target: @council_member, metadata: { name: @council_member.display_name })
      @council_member.destroy!
      redirect_to admin_council_members_path, notice: "Council member deleted."
    end

    private

    def council_member_params
      params.expect(council_member: [ :first_name, :last_name, :seat, :term_start, :term_end ])
    end
  end
end
