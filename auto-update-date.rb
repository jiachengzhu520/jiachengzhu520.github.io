#!/usr/bin/env ruby

require 'fileutils'
require 'find'
require 'time'

# 监控的目录
POSTS_DIR = '_posts'

# 检查文件是否为 Markdown 文件
def markdown_file?(file)
  file.end_with?('.md') || file.end_with?('.markdown')
end

# 读取文件内容
def read_file(file)
  File.read(file, encoding: 'UTF-8')
end

# 写入文件内容
def write_file(file, content)
  File.write(file, content, encoding: 'UTF-8')
end

# 从文件名中提取日期
def extract_date_from_filename(file)
  # 匹配 Jekyll 博客文件名格式：YYYY-MM-DD-title.md
  if File.basename(file) =~ /^(\d{4}-\d{2}-\d{2})-/i
    begin
      Date.parse($1)
    rescue ArgumentError
      nil
    end
  else
    nil
  end
end

# 检查是否应该更新日期
def should_update_date?(file)
  # 从文件名提取日期
  file_date = extract_date_from_filename(file)
  
  if file_date
    # 比较文件名日期与当前日期
    current_date = Date.today
    if file_date < current_date
      # 文件名日期早于当前日期，不更新
      puts "⏰ Filename date (#{file_date}) is earlier than current date (#{current_date}), skipping date update"
      false
    else
      # 文件名日期不早于当前日期，可以更新
      true
    end
  else
    # 无法从文件名提取日期，默认更新
    puts "📅 No date found in filename, will update date"
    true
  end
end

# 更新文件中的日期
def update_date(file)
  # 检查是否应该更新日期
  return unless should_update_date?(file)
  
  content = read_file(file)
  
  # 查找并更新 YAML Front Matter 中的 date 字段
  if content =~ /\A---\s*\n(.+?)\n---\s*\n(.+)/m
    front_matter = $1
    rest_content = $2
    
    # 手动构建带有时区信息的时间字符串
    t = Time.now
    year = t.year
    month = t.month.to_s.rjust(2, '0')
    day = t.day.to_s.rjust(2, '0')
    hour = t.hour.to_s.rjust(2, '0')
    min = t.min.to_s.rjust(2, '0')
    sec = t.sec.to_s.rjust(2, '0')
    # 计算时区偏移
    offset = t.utc_offset / 3600
    sign = offset >= 0 ? '+' : '-'
    offset_hour = offset.abs.to_s.rjust(2, '0')
    timezone = "#{sign}#{offset_hour}00"
    
    # 构建最终时间字符串
    current_time = "#{year}-#{month}-#{day} #{hour}:#{min}:#{sec} #{timezone}"
    
    # 调试信息
    puts "DEBUG: Current time: #{current_time}"
    puts "DEBUG: UTC offset: #{t.utc_offset} seconds"
    puts "DEBUG: Offset hours: #{offset}"
    puts "DEBUG: Timezone: #{timezone}"
    
    # 更新 date 字段
    if front_matter =~ /^date:\s*.+$/m
      new_front_matter = front_matter.sub(/^date:\s*.+$/m, "date: #{current_time}")
    else
      # 如果没有 date 字段，添加一个
      new_front_matter = front_matter + "\ndate: #{current_time}"
    end
    
    # 重新组合文件内容
    new_content = "---\n#{new_front_matter}\n---\n#{rest_content}"
    
    # 写入更新后的内容
    write_file(file, new_content)
    puts "✓ Updated date in #{file} to #{current_time}"
  else
    puts "⚠ No YAML front matter found in #{file}"
  end
end

# 监控文件变化
def monitor_files
  puts "Monitoring #{POSTS_DIR} for changes..."
  puts "Press Ctrl+C to exit"
  
  # 存储文件的修改时间和内容哈希
  file_info = {}
  
  # 计算文件内容的哈希值
def content_hash(file)
    require 'digest'
    Digest::MD5.hexdigest(read_file(file))
  rescue Errno::ENOENT
    nil
  end
  
  # 初始化文件信息
  Find.find(POSTS_DIR) do |path|
    if File.file?(path) && markdown_file?(path)
      begin
        file_info[path] = {
          mtime: File.mtime(path),
          content_hash: content_hash(path)
        }
        puts "Initialized: #{path} (last modified: #{file_info[path][:mtime]})"
      rescue Errno::ENOENT
        puts "⚠ File not found: #{path}"
      end
    end
  end
  
  puts "\nReady to update dates only when content changes..."
  puts "Each save operation will be checked for actual content changes."
  
  # 循环监控
  loop do
    Find.find(POSTS_DIR) do |path|
      if File.file?(path) && markdown_file?(path)
        begin
          current_mtime = File.mtime(path)
          current_hash = content_hash(path)
          
          # 检查文件是否被修改
          if file_info[path]
            # 检查内容是否真正变化
            if file_info[path][:content_hash] != current_hash
              puts "\n🔄 Detected content change in: #{path}"
              update_date(path)
              # 更新文件信息（包括新的内容哈希）
              file_info[path][:mtime] = current_mtime
              file_info[path][:content_hash] = content_hash(path)  # 重新计算哈希，因为我们修改了文件
              puts "📝 Updated tracking information for next save operation"
            elsif file_info[path][:mtime] != current_mtime
              # 只是保存操作，内容没有变化
              puts "\n⏭ Save operation detected but no content change in: #{path}"
              # 更新修改时间跟踪，但不更新日期
              file_info[path][:mtime] = current_mtime
              puts "📅 Updated modification time tracking only"
            end
          else
            # 新文件，初始化跟踪
            file_info[path] = {
              mtime: current_mtime,
              content_hash: current_hash
            }
            puts "\n🆕 New file detected: #{path}"
            puts "📋 Initialized tracking"
          end
        rescue Errno::ENOENT
          # 文件被删除，从跟踪列表中移除
          if file_info[path]
            file_info.delete(path)
            puts "\n🗑 File deleted: #{path}"
          end
        end
      end
    end
    
    # 短暂休眠，减少 CPU 占用
    sleep 1
  end
end

# 主函数
if __FILE__ == $0
  # 检查目录是否存在
  unless File.directory?(POSTS_DIR)
    puts "Error: #{POSTS_DIR} directory not found"
    exit 1
  end
  
  # 启动监控
  begin
    monitor_files
  rescue Interrupt
    puts "\nExiting..."
    exit 0
  end
end
