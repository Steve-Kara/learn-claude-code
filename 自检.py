#!/usr/bin/env python3
r"""自检：验证 .env 里的密钥 / 端点 / 模型是否都能用。

用法（在本目录下）：
    .\.venv\Scripts\python.exe 自检.py

它会做一次最小的真实请求，所以能立刻暴露：密钥错(401)、端点错(404)、模型名错(400)
等问题。不会打印你的密钥，只打印指纹（前 6 位 + 长度）。

注意：本文件刻意只用 ASCII 标记（[OK]/[X]），因为 Windows 控制台默认是 GBK 编码，
      ○ ✓ ✗ 这类符号会触发 UnicodeEncodeError。
"""
import os
import sys

from anthropic import Anthropic
from dotenv import load_dotenv

load_dotenv(override=True)

key = os.getenv("ANTHROPIC_API_KEY") or ""
base = os.getenv("ANTHROPIC_BASE_URL") or "(官方默认)"
model = os.getenv("MODEL_ID") or ""

print("=" * 60)
print("配置自检")
print("=" * 60)

# 1) 密钥
if not key or key.startswith("PUT_YOUR"):
    print("[X] ANTHROPIC_API_KEY 还没填（仍是占位符）")
    print("    -> 申请：https://platform.deepseek.com/api_keys")
    print("    -> 然后编辑 .env 把这一行换成 sk- 开头的密钥")
    sys.exit(1)
fingerprint = (key[:6] + "..." + key[-4:]) if len(key) > 12 else "(太短!)"
print(f"[OK] 密钥: {fingerprint}   长度 {len(key)}")
if not key.startswith("sk-"):
    print("     [!] DeepSeek 的密钥一般以 sk- 开头，你这个不是，确认一下？")
if len(key) < 20:
    print("     [!] 密钥看起来偏短，可能没复制全")

# 2) 端点与模型
print(f"[OK] 端点: {base}")
if not model:
    print("[X] MODEL_ID 没设置")
    sys.exit(1)
print(f"[OK] 模型: {model}")

# 3) 真实请求
print("-" * 60)
print("发起一次真实请求（会消耗几个 token）...")
try:
    client = Anthropic(base_url=os.getenv("ANTHROPIC_BASE_URL"))
    resp = client.messages.create(
        model=model,
        max_tokens=200,
        messages=[{"role": "user", "content": "只回答四个字：链路通畅"}],
    )
    text = "".join(b.text for b in resp.content if getattr(b, "type", None) == "text")
    print(f"[OK] 模型回复: {text.strip()}")
    u = resp.usage
    print(f"[OK] token 用量: 输入 {u.input_tokens} / 输出 {u.output_tokens}")
    print("-" * 60)
    print("一切正常，可以去跑台阶了:  run.cmd")
except Exception as e:
    print(f"[X] 请求失败: {type(e).__name__}: {e}")
    print("-" * 60)
    print("常见原因：")
    print("  401 / authentication  -> 密钥不对或没复制全")
    print("  404 / model           -> MODEL_ID 写错（可用 deepseek-v4-flash / deepseek-v4-pro）")
    print("  余额不足              -> 去 platform.deepseek.com 充值")
    sys.exit(1)
