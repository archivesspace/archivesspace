class DigitalObjectsController < ApplicationController
  def tree_root
    @root_uri = "/repositories/#{params[:rid]}/digital_objects/#{params[:id]}"

    render :json => archivesspace.get_raw_record(@root_uri + '/tree/root')
  end

  def tree_node
    @root_uri = "/repositories/#{params[:rid]}/digital_objects/#{params[:id]}"

    render :json => archivesspace.get_raw_record(@root_uri + '/tree/node_' + params[:node])
  end

  def tree_waypoint
    @root_uri = "/repositories/#{params[:rid]}/digital_objects/#{params[:id]}"

    render :json => archivesspace.get_raw_record(@root_uri + '/tree/waypoint_' + params[:node] + '_' + params[:offset])
  end

  def tree_node_from_root
    @root_uri = "/repositories/#{params[:rid]}/digital_objects/#{params[:id]}"

    render :json => archivesspace.get_raw_record(@root_uri + '/tree/node_from_root_' + params[:node_ids].first)
  end
end