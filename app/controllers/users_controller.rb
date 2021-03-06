class UsersController < ApplicationController  
  before_filter :login_required, :only => [:dashboard, :edit, :update]
  before_filter :find_user, :only => [:suspend, :unsuspend, :destroy, :purge, :show, :edit, :update, :relationships]
  before_filter :ensure_user_is_current_user_or_admin, :only => [:edit, :update]
  before_filter :ensure_user_is_admin, :only => [:suspend, :unsuspend]
  
  def new
    @user = User.new
  end
 
  def create
    logout_keeping_session!
    @user = User.new(params[:user])
    @user.register! if @user && @user.valid?
    success = @user && @user.valid?
    if success && @user.errors.empty?
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    else
      render :action => 'new'
    end
  end

  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && user && !user.active?
      user.activate!
      flash[:notice] = "Your iNaturalist.org account has been verified! Please sign in to continue."
      redirect_to '/login'
    when params[:activation_code].blank?
      flash[:error] = "Your activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else 
      flash[:error]  = "We couldn't find a user with that activation code. You may have already activated your account, please try signing in."
      redirect_back_or_default('/')
    end
  end

  # Don't take these out yet, useful for admin user management down the road

  def suspend
     @user.suspend! 
     flash[:notice] = "The user #{@user.login} has been suspended"
     redirect_to users_path
  end
   
  def unsuspend
    @user.unsuspend! 
    flash[:notice] = "The user #{@user.login} has been unsuspended"
    redirect_to users_path
  end
  
  # There's no page here to update or destroy a user.  If you add those, be
  # smart -- make sure you check that the visitor is authorized to do so, that they
  # supply their old password along with a new one to update it, etc.
  
  # Methods below here are added by iNaturalist
  
  def index
    update_find_options = {
      :limit => 10, 
      :order => "created_at DESC"
    }
    
    @updates = [
      Observation.find(:all, update_find_options),
      Identification.find(:all, update_find_options),
      Post.find(:all, update_find_options),
      Comment.find(:all, update_find_options)
    ].flatten.sort{|a,b| b.created_at <=> a.created_at}.group_by(&:user)


    find_options = {
      :page => params[:page] || 1, :order => 'login'
    }
    if @letter = params[:letter]
      find_options.update(:conditions => [
        "login LIKE ?", "#{params[:letter].first}%"])
    end
    @users = User.paginate(find_options)
    
    @users_by_letter = User.count(:group => "LOWER(LEFT(login, 1))")
    alphabet = %w"a b c d e f g h i j k l m n o p q r s t u v w x y z"
    @users_by_letter = alphabet.map do |letter|
      [letter, @users_by_letter[letter] || 0]
    end
    
    respond_to do |format|
      format.html
      # These currently display all of the users' private info.  I'll work on filtering them out later.
      # format.xml   {render :xml => @users}
      # format.json  {render :json => @users.to_json}
    end
  end
  
  def show
    # All the magic is done in the before_filter
  end
  
  def relationships
    update_find_options = {
      :limit => 10, 
      :order => "created_at DESC"
    }
    
    # @updates = [
    #   Observation.find(:all, update_find_options),
    #   Identification.find(:all, update_find_options),
    #   Post.find(:all, update_find_options),
    #   Comment.find(:all, update_find_options)
    # ].flatten.sort{|a,b| b.created_at <=> a.created_at}.group_by(&:user)

    find_options = {
      :page => params[:page] || 1, :order => 'login'
    }
    if @letter = params[:letter]
      find_options.update(:conditions => [
        "login LIKE ?", "#{params[:letter].first}%"])
    end
    
    if (params[:following])
      @users = User.find_by_login(params[:login]).friends.paginate(find_options)
    elsif (params[:followers])
      @users = User.find_by_login(params[:login]).followers.paginate(find_options)
    end
    
    # @users_by_letter = User.count(:group => "LOWER(LEFT(login, 1))")
    # alphabet = %w"a b c d e f g h i j k l m n o p q r s t u v w x y z"
    # @users_by_letter = alphabet.map do |letter|
    #   [letter, @users_by_letter[letter] || 0]
    # end
    
    render :action => 'index'
    return
  end
  
  # These are protected by login_required
  def dashboard
    @user = current_user
    @recently_commented = Observation.find(:all,
      :include => :comments,
      :conditions => [
        "observations.user_id = ? AND comments.created_at > ?", 
        @user, 1.week.ago],
      :order => "comments.created_at DESC"
    )
    
    if @recently_commented.empty?
      @commented_on = Observation.find(:all,
        :include => [:comments],
        :conditions => [
          "comments.user_id = ? AND comments.created_at > ?", 
          @user, 1.week.ago],
        :order => "comments.created_at DESC"
      ).uniq
    else
      @commented_on = Observation.find(:all,
        :include => [:comments],
        :conditions => [
          "comments.user_id = ? AND comments.created_at > ? AND observations.id NOT IN (?)", 
          @user, 1.week.ago, @recently_commented],
        :order => "comments.created_at DESC"
      ).uniq
    end
  end
  
  def edit
  end
  
  def update
    @user = current_user
    @login = @user.login
    @original_user = @user
    
    # Add a friend
    unless(params[:friend_id].nil?)
      current_user.friends << User.find(params[:friend_id])
      return redirect_back_or_default(person_by_login_path({:login => current_user.login}))
    end
    
    # Remove a friend
    unless(params[:remove_friend_id].nil?)
      current_user.friendships.find_by_friend_id(params[:remove_friend_id]).destroy
      return redirect_back_or_default(person_by_login_path({:login => current_user.login}))
    end
    
    # Update passwords
    unless(params[:password].nil?)
      if current_user.authenticated?(params[:current_password])
        current_user.password = params[:password]
        current_user.password_confirmation = params[:password_confirmation]
        begin
          current_user.save!
          flash[:notice] = 'Successfully changed your password.'
        rescue ActiveRecord::RecordInvalid => e
          flash[:error] = "Couldn't change your password: #{e}"
          return redirect_to(edit_person_path(@user))
        end
      else
        flash[:error] = "Couldn't change your password: is that really your current password?"
        return redirect_to(edit_person_path(@user))
      end
      return redirect_to(person_by_login_path(:login => current_user.login))
    end
    
    # Update the preferences
    @user.preferences ||= Preferences.new
    if params[:user] && params[:user][:preferences]
      @user.preferences.update_attributes(params[:user][:preferences])
    end
    
    if @user.update_attributes(params[:user])
      flash[:notice] = 'Your profile was successfully updated!'
      redirect_to(person_by_login_path(:login => @user.login))
    else
      render :action => 'edit', :login => @original_user.login
    end
  end

protected
  def find_user
    params[:id] ||= params[:login]
    begin
      @user = User.find(params[:id])
    rescue
      @user = User.find_by_login(params[:id])
      raise ActiveRecord::RecordNotFound if @user.nil?
    end
  end
  
  def ensure_user_is_current_user_or_admin
    unless current_user.has_role? :admin
      redirect_to edit_user_path(current_user, :id => current_user.login) if @user.id != current_user.id
    end
  end
  
  def ensure_user_is_admin
    unless current_user.has_role? :admin
      redirect_to user_path(current_user, :id => current_user.login)
    end
  end
    
end
