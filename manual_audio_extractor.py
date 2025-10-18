#!/usr/bin/env python3
"""
手动选择音效片段的工具
可以让你预览音频文件并手动选择每个音效的时间范围
"""

import os
import subprocess
import wave

def get_audio_info(file_path):
    """获取音频文件信息"""
    try:
        with wave.open(file_path, 'rb') as wav_file:
            frames = wav_file.getnframes()
            sample_rate = wav_file.getframerate()
            duration = frames / sample_rate
            return {
                'duration': duration,
                'sample_rate': sample_rate,
                'frames': frames
            }
    except Exception as e:
        print(f"无法读取音频文件: {e}")
        return None

def preview_segment(input_file, start_time, duration=1.0):
    """预览音频片段"""
    try:
        # 创建临时文件
        temp_file = "temp_preview.wav"
        
        cmd = [
            'ffmpeg', '-i', input_file,
            '-ss', str(start_time),
            '-t', str(duration),
            '-y', temp_file
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"✓ 预览片段已生成: {temp_file}")
            print(f"  时间范围: {start_time:.2f}s - {start_time + duration:.2f}s")
            print(f"  请播放 {temp_file} 来试听音效")
            return temp_file
        else:
            print(f"✗ 预览失败: {result.stderr}")
            return None
    except Exception as e:
        print(f"✗ 预览失败: {e}")
        return None

def extract_custom_clip(input_file, start_time, end_time, output_file):
    """提取自定义音效片段"""
    try:
        duration = end_time - start_time
        
        cmd = [
            'ffmpeg', '-i', input_file,
            '-ss', str(start_time),
            '-t', str(duration),
            '-acodec', 'mp3',
            '-ab', '128k',
            '-y', output_file
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print(f"✓ 音效提取成功: {output_file}")
            return True
        else:
            print(f"✗ 音效提取失败: {result.stderr}")
            return False
    except Exception as e:
        print(f"✗ 音效提取失败: {e}")
        return False

def interactive_extractor():
    """交互式音效提取器"""
    input_file = "assets/audio/762132__ienba__ui-buttons.wav"
    
    if not os.path.exists(input_file):
        print(f"音频文件不存在: {input_file}")
        return
    
    # 获取音频信息
    info = get_audio_info(input_file)
    if not info:
        return
    
    duration = info['duration']
    print(f"音频文件时长: {duration:.2f} 秒")
    
    # 音效类型配置
    sound_types = {
        "button_click": "按钮点击音效",
        "card_deal": "发牌音效", 
        "card_play": "出牌音效",
        "bid": "叫分音效",
        "pass": "过牌音效",
        "win": "胜利音效",
        "lose": "失败音效",
        "landlord": "成为地主音效"
    }
    
    print(f"\n开始交互式音效提取...")
    print(f"请为每个音效类型选择时间范围")
    print(f"输入格式: 开始时间,结束时间 (例如: 0.5,1.2)")
    print(f"输入 'skip' 跳过当前音效")
    print(f"输入 'quit' 退出")
    
    for sound_key, sound_name in sound_types.items():
        print(f"\n--- {sound_name} ---")
        
        while True:
            user_input = input(f"请输入时间范围 (0-{duration:.1f}s): ").strip()
            
            if user_input.lower() == 'quit':
                print("退出音效提取")
                return
            elif user_input.lower() == 'skip':
                print(f"跳过 {sound_name}")
                break
            
            try:
                # 解析输入
                if ',' in user_input:
                    start_str, end_str = user_input.split(',')
                    start_time = float(start_str.strip())
                    end_time = float(end_str.strip())
                else:
                    print("格式错误，请使用: 开始时间,结束时间")
                    continue
                
                # 验证时间范围
                if start_time < 0 or end_time > duration or start_time >= end_time:
                    print(f"时间范围无效，请确保: 0 <= 开始时间 < 结束时间 <= {duration:.1f}")
                    continue
                
                # 预览音效
                preview_duration = min(2.0, end_time - start_time)
                preview_file = preview_segment(input_file, start_time, preview_duration)
                
                if preview_file:
                    confirm = input("这个音效合适吗？(y/n/preview): ").strip().lower()
                    
                    if confirm == 'y':
                        # 提取音效
                        output_file = f"assets/audio/{sound_key}.mp3"
                        if extract_custom_clip(input_file, start_time, end_time, output_file):
                            print(f"✓ {sound_name} 提取完成")
                        break
                    elif confirm == 'preview':
                        # 重新预览
                        continue
                    else:
                        print("请重新输入时间范围")
                        continue
                else:
                    print("预览失败，请重新输入")
                    continue
                    
            except ValueError:
                print("输入格式错误，请输入数字")
                continue
    
    print(f"\n音效提取完成！")
    print(f"所有音效文件已保存到 assets/audio/ 目录")

if __name__ == "__main__":
    interactive_extractor()
