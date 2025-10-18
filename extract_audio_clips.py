#!/usr/bin/env python3
"""
从多音效WAV文件中裁剪出不同的音效片段
"""

import os
import subprocess
import wave
import struct

def get_audio_info(file_path):
    """获取音频文件信息"""
    try:
        with wave.open(file_path, 'rb') as wav_file:
            frames = wav_file.getnframes()
            sample_rate = wav_file.getframerate()
            duration = frames / sample_rate
            channels = wav_file.getnchannels()
            sample_width = wav_file.getsampwidth()
            
            print(f"音频文件信息:")
            print(f"  时长: {duration:.2f} 秒")
            print(f"  采样率: {sample_rate} Hz")
            print(f"  声道数: {channels}")
            print(f"  采样位深: {sample_width * 8} bit")
            print(f"  总帧数: {frames}")
            return {
                'duration': duration,
                'sample_rate': sample_rate,
                'channels': channels,
                'sample_width': sample_width,
                'frames': frames
            }
    except Exception as e:
        print(f"无法读取音频文件: {e}")
        return None

def extract_audio_clips(input_file, output_dir="assets/audio"):
    """从音频文件中提取不同的音效片段"""
    
    # 创建输出目录
    os.makedirs(output_dir, exist_ok=True)
    
    # 获取音频信息
    info = get_audio_info(input_file)
    if not info:
        return
    
    duration = info['duration']
    sample_rate = info['sample_rate']
    
    print(f"\n开始裁剪音效片段...")
    
    # 定义要提取的音效片段（时间范围，单位：秒）
    clips = {
        "button_click.mp3": {
            "start": 0.0,
            "end": 0.3,
            "desc": "按钮点击音效"
        },
        "card_deal.mp3": {
            "start": 0.3,
            "end": 1.0,
            "desc": "发牌音效"
        },
        "card_play.mp3": {
            "start": 1.0,
            "end": 1.5,
            "desc": "出牌音效"
        },
        "bid.mp3": {
            "start": 1.5,
            "end": 2.0,
            "desc": "叫分音效"
        },
        "pass.mp3": {
            "start": 2.0,
            "end": 2.5,
            "desc": "过牌音效"
        },
        "win.mp3": {
            "start": 2.5,
            "end": 3.5,
            "desc": "胜利音效"
        },
        "lose.mp3": {
            "start": 3.5,
            "end": 4.5,
            "desc": "失败音效"
        },
        "landlord.mp3": {
            "start": 4.5,
            "end": 5.5,
            "desc": "成为地主音效"
        }
    }
    
    # 如果音频文件太短，自动调整时间范围
    if duration < 6.0:
        print(f"音频文件较短（{duration:.2f}秒），自动调整时间范围...")
        # 将整个文件分成8个等长片段
        segment_duration = duration / 8
        for i, (filename, config) in enumerate(clips.items()):
            config['start'] = i * segment_duration
            config['end'] = (i + 1) * segment_duration
    
    # 提取每个音效片段
    for filename, config in clips.items():
        start_time = config['start']
        end_time = config['end']
        duration_clip = end_time - start_time
        
        # 确保不超过原文件长度
        if start_time >= duration:
            print(f"跳过 {filename} - 开始时间超出文件长度")
            continue
        
        if end_time > duration:
            end_time = duration
            duration_clip = end_time - start_time
        
        output_path = os.path.join(output_dir, filename)
        
        try:
            print(f"提取 {config['desc']} ({start_time:.2f}s - {end_time:.2f}s)...")
            
            # 使用FFmpeg裁剪音频
            cmd = [
                'ffmpeg', '-i', input_file,
                '-ss', str(start_time),
                '-t', str(duration_clip),
                '-acodec', 'mp3',
                '-ab', '128k',
                '-y', output_path
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"✓ {filename} 提取成功")
            else:
                print(f"✗ {filename} 提取失败: {result.stderr}")
                
        except Exception as e:
            print(f"✗ {filename} 提取失败: {e}")
    
    print(f"\n音效提取完成！")
    print(f"提取的音效文件保存在: {output_dir}/")

def preview_audio_segments(input_file, segment_duration=0.5):
    """预览音频文件的不同片段"""
    info = get_audio_info(input_file)
    if not info:
        return
    
    duration = info['duration']
    segments = int(duration / segment_duration)
    
    print(f"\n音频文件预览（每{segment_duration}秒一个片段）:")
    for i in range(segments):
        start_time = i * segment_duration
        end_time = min((i + 1) * segment_duration, duration)
        print(f"  片段 {i+1}: {start_time:.2f}s - {end_time:.2f}s")

if __name__ == "__main__":
    input_file = "assets/audio/762132__ienba__ui-buttons.wav"
    
    if not os.path.exists(input_file):
        print(f"音频文件不存在: {input_file}")
        print("请确保文件路径正确")
        exit(1)
    
    # 预览音频文件
    preview_audio_segments(input_file)
    
    # 提取音效片段
    extract_audio_clips(input_file)
