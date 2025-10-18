#!/usr/bin/env python3
"""
从 Freesound.org 下载免费音效
需要先注册账号并获取 API key
"""

import os
import requests
import json
import time
import subprocess

# Freesound API 配置
# 你需要先注册 https://freesound.org/ 账号并获取 API key
FREESOUND_API_KEY = "YOUR_API_KEY_HERE"  # 请替换为你的 API key
FREESOUND_BASE_URL = "https://freesound.org/apiv2"

def search_sounds(query, duration_max=2.0, page_size=5):
    """搜索音效"""
    url = f"{FREESOUND_BASE_URL}/search/text/"
    params = {
        'query': query,
        'filter': f'duration:[0 TO {duration_max}]',
        'fields': 'id,name,download,previews',
        'page_size': page_size,
        'sort': 'rating_desc'
    }
    headers = {'Authorization': f'Token {FREESOUND_API_KEY}'}
    
    try:
        response = requests.get(url, params=params, headers=headers)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"搜索失败: {e}")
        return None

def download_sound(sound_id, filename):
    """下载音效文件"""
    # 获取下载链接
    url = f"{FREESOUND_BASE_URL}/sounds/{sound_id}/"
    headers = {'Authorization': f'Token {FREESOUND_API_KEY}'}
    
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()
        
        download_url = data['download']
        print(f"下载 {filename}...")
        
        # 下载文件
        response = requests.get(download_url, headers=headers)
        response.raise_for_status()
        
        with open(filename, 'wb') as f:
            f.write(response.content)
        
        print(f"✓ {filename} 下载成功")
        return True
        
    except Exception as e:
        print(f"✗ {filename} 下载失败: {e}")
        return False

def convert_to_mp3(input_file, output_file):
    """使用 FFmpeg 转换为 MP3"""
    try:
        cmd = [
            'ffmpeg', '-i', input_file, '-acodec', 'mp3', 
            '-ab', '128k', '-y', output_file
        ]
        subprocess.run(cmd, check=True, capture_output=True)
        os.remove(input_file)  # 删除原文件
        return True
    except Exception as e:
        print(f"转换失败: {e}")
        return False

def download_game_sounds():
    """下载游戏音效"""
    
    if FREESOUND_API_KEY == "YOUR_API_KEY_HERE":
        print("请先获取 Freesound API key:")
        print("1. 访问 https://freesound.org/")
        print("2. 注册账号并登录")
        print("3. 访问 https://freesound.org/docs/api/authentication.html")
        print("4. 获取 API key 并替换脚本中的 YOUR_API_KEY_HERE")
        return
    
    # 创建音频目录
    audio_dir = "assets/audio"
    os.makedirs(audio_dir, exist_ok=True)
    
    # 音效搜索配置
    sound_configs = {
        "button_click.mp3": {
            "query": "button click ui interface",
            "duration_max": 0.5,
            "description": "按钮点击音效"
        },
        "card_deal.mp3": {
            "query": "card shuffle dealing",
            "duration_max": 2.0,
            "description": "发牌音效"
        },
        "card_play.mp3": {
            "query": "card flip play",
            "duration_max": 1.0,
            "description": "出牌音效"
        },
        "bid.mp3": {
            "query": "beep notification alert",
            "duration_max": 1.0,
            "description": "叫分音效"
        },
        "pass.mp3": {
            "query": "beep skip pass",
            "duration_max": 1.0,
            "description": "过牌音效"
        },
        "win.mp3": {
            "query": "victory win success",
            "duration_max": 3.0,
            "description": "胜利音效"
        },
        "lose.mp3": {
            "query": "defeat lose failure",
            "duration_max": 3.0,
            "description": "失败音效"
        },
        "landlord.mp3": {
            "query": "special achievement unlock",
            "duration_max": 2.0,
            "description": "成为地主音效"
        },
        "bgm.mp3": {
            "query": "background music ambient",
            "duration_max": 30.0,
            "description": "背景音乐"
        }
    }
    
    print("开始从 Freesound.org 下载音效...")
    
    for filename, config in sound_configs.items():
        filepath = os.path.join(audio_dir, filename)
        
        print(f"\n搜索 {config['description']}...")
        results = search_sounds(config['query'], config['duration_max'])
        
        if not results or not results.get('results'):
            print(f"未找到 {config['description']}，跳过")
            continue
        
        # 选择第一个结果
        sound = results['results'][0]
        sound_id = sound['id']
        sound_name = sound['name']
        
        print(f"找到音效: {sound_name}")
        
        # 下载文件
        temp_file = f"temp_{filename}"
        if download_sound(sound_id, temp_file):
            # 转换为 MP3
            if convert_to_mp3(temp_file, filepath):
                print(f"✓ {filename} 处理完成")
            else:
                print(f"✗ {filename} 转换失败")
        else:
            print(f"✗ {filename} 下载失败")
        
        # 避免请求过于频繁
        time.sleep(1)
    
    print("\n下载完成！")
    print("注意：请确保遵守 Freesound.org 的使用条款和版权要求")

if __name__ == "__main__":
    download_game_sounds()
