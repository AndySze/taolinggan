# coding: utf-8
module TopicsHelper

  def render_topic_node_select_tag(topic)
    return if topic.blank?
    grouped_collection_select :topic, :node_id, Plane.all,
                    :sorted_nodes, :name, :id, :name, {:value => topic.node_id,
                    :prompt => "选择节点"}, :style => "width:245px;"
  end

end
