module Admin
  class TagRulesController < BaseController
    def create
      @tag = Tag.find(params[:tag_id])
      @rule = @tag.tag_rules.build(rule_params)

      if @rule.save
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to admin_tags_path }
        end
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("new_rule_form_#{@tag.id}", partial: "admin/tag_rules/form", locals: { tag: @tag, rule: @rule }) }
          format.html { redirect_to admin_tags_path, alert: @rule.errors.full_messages.to_sentence }
        end
      end
    end

    def destroy
      @rule = TagRule.find(params[:id])
      @tag = @rule.tag
      @rule.destroy

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_tags_path }
      end
    end

    private

    def rule_params
      params.require(:tag_rule).permit(:pattern, :match_type)
    end
  end
end
