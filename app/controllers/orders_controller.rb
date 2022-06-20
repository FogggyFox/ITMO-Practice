class OrdersController < ApplicationController
  def new
    @order = Order.new
    @options = Option.all
  end

  def create
    @user = User.find(params[:client_id])
    @order = Order.new(from: order_params[:from], to: order_params[:to], tariff: order_params[:tariff])
    order_service = OrderService.new(@order)
    order_service.assemble(@user)
    user_service = UserService.new(@user)
    if order_service.save
      user_service.new_order(order_service.order)
      if order_params[:message].present?
        @assemble_message = CreateMessage.new(order_params[:message], order_service.order)
        @assemble_message.save
      end
      ConnectOptions.new(order_params, @order).connect
      redirect_to user_path(@user)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @order = Order.find(params[:id])
    @client = User.find(@order.client_id)
    @driver = User.find(@order.driver_id)
    @new_driver = User.find(params[:user_id])
    @info = OrderService.new(@order).get_info
    @driver_service = DriverService.new(@new_driver)
  end

  def edit
    @order = Order.find(params[:id])
    @options = Option.all
  end

  def update
    @order = Order.find(params[:id])

    if @order.update(order_params)
      redirect_to @order
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order = Order.find(params[:id])
    order_service = OrderService.new(@order)
    order_service.destroy
    redirect_to :action => 'index'
  end

  def index
    @orders = Order.all
    @users = User.all
    @driver = User.find(params[:user_id])
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @orders }
    end
  end

  def cancel
    @order = Order.find(params[:id])
    @driver = User.find(params[:user_id])
    DriverService.new(@driver).cancel_order
    redirect_to order_path(@order, user_id: params[:user_id])
  end

  def accept
    @order = Order.find(params[:id])
    @driver = User.find(params[:user_id])
    DriverService.new(@driver).accept(@order)
    redirect_to order_path(@order, user_id: params[:user_id])
  end
  
  private
  def order_params
    options = Option.all
    option_names = options.map(&:name)
    params.require(:order).permit(:from, :to, :tariff, :message, option_names)
  end


end
