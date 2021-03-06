class IdentificationsController < ApplicationController
  before_filter :login_required, :except => [:by_login]
  before_filter :load_user_by_login, :only => [:by_login]
  before_filter :load_identification, :only => [:edit, :update, :destroy]
  before_filter :require_owner, :only => [:edit, :update, :destroy]
  cache_sweeper :comment_sweeper, :only => [:create, :update, :destroy, 
    :agree]

  def by_login
    @identifications = @selected_user.identifications.for_others.paginate(
      :page => params[:page],
      :per_page => 20,
      :include => [:observation, :taxon],
      :order => "identifications.created_at DESC"
    )
    @identifications_by_obs_id = @identifications.index_by(&:observation_id)
    @observations = @identifications.collect(&:observation)
    @other_ids = Identification.all(
      :conditions => [
        "observation_id in (?) AND user_id != ?", @observations, @selected_user
      ],
      :include => [:observation, :taxon]
    )
    @other_id_stats = {}
    @other_ids.group_by(&:observation).each do |obs, ids|
      user_ident = @identifications_by_obs_id[obs.id]
      agreements = ids.select do |ident|
        ident.in_agreement_with?(user_ident)
      end
      @other_id_stats[obs.id] = {
        :num_agreements => agreements.size,
        :num_disagreements => ids.size - agreements.size
      }
    end
  end
  
  # POST identification_url
  def create
    @identification = Identification.new(params[:identification])
    if @identification.taxon.nil? and params[:taxa_search_form_taxon_name]
      taxon_name = TaxonName.find_by_name(params[:taxa_search_form_taxon_name])
      @identification.taxon = taxon_name.taxon if taxon_name
    end
    respond_to do |format|
      if @identification.save
        format.html do
          flash[:notice] = "Identification saved!"
          if params[:return_to]
            return redirect_to(params[:return_to])
          end
          redirect_to @identification.observation and return
        end
        format.js
      else
        format.html do
          flash[:error] = "There was a problem saving your identification: " +
            @identification.errors.full_messages.join(', ')
          if params[:return_to]
            return redirect_to(params[:return_to])
          end
          redirect_to @identification.observation and return
        end
        format.js { render :action => 'creation_error.js.rjs' }
      end
    end
  end
  
  def edit
  end
  
  def update
    if @identification.update_attributes(params[:identification])
      flash[:notice] = "Identification updated!"
    else
      flash[:error] = "There was a problem saving your identification: " +
        @identification.errors.full_messages.join(', ')
    end
    redirect_to @identification.observation
  end
  

  # DELETE identification_url
  def destroy
    observation = @identification.observation
    @identification.destroy
    respond_to do |format|
      format.html do
        flash[:notice] = "Identification deleted."
        redirect_to observation
      end
      format.js
    end
  end
  
## Custom actions ############################################################

  # Agree with an identification
  def agree
    @observation = Observation.find_by_id(params[:observation_id])
    @old_identification = @observation.identifications.find(:first,
      :conditions => ["user_id = ?", current_user.id])
    if @old_identification && @old_identification.taxon_id == params[:taxon_id]
      @identification = @old_identification
    else
      @old_identification.destroy if @old_identification
      @identification = Identification.new(
        :user => current_user,
        :taxon_id => params[:taxon_id],
        :observation_id => params[:observation_id]
      )
    end
    
    respond_to do |format|
      if @identification.save
        format.html do
          flash[:notice] = "Identification saved!"
          if params[:return_to]
            return redirect_to(params[:return_to])
          end
          redirect_to @identification.observation and return
        end
        format.js
      else
        format.html do
          flash[:notice] = "There was a problem saving your identification: " +
            @identification.errors.full_messages.join(', ')
          if params[:return_to]
            return redirect_to(params[:return_to])
          end
          redirect_to @identification.observation and return
        end
        format.js { render :action => 'agreement_error.js.rjs' }
      end
    end
  end
  
  private
  
  def load_identification
    @identification = Identification.find(params[:id])
  end
  
  def require_owner
    unless logged_in? && @identification.user_id == current_user.id
      redirect_to_hell
    end
  end
end
