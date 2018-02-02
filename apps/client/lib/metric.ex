defmodule Metric do
  def fetch_cpu_usage do
    :cpu
  end

  def fetch_memory_usage do
    :memory
  end

  def fetch_disk_usage do
    :disk
  end

  def fetch_network_usage do
    :network
  end
end
