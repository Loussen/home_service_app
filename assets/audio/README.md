# Voice search prompts (ElevenLabs)

Place files here after generating in ElevenLabs. **Prefer `.m4a` (AAC)** — iOS AVPlayer is more reliable than MP3 with C2PA metadata.

| File | When played |
|------|-------------|
| `voice_greeting_{az,en,ru}.m4a` | Voice tab opens |
| `voice_accepted_{az,en,ru}.m4a` | After user finishes voice recording |

`.mp3` is kept as fallback.

## Scripts — greeting

**AZ** — My Sancho sizi salamlayır. Xahiş olunur, səsli axtarış edin və ehtiyacınızı ətraflı bildirin.

**EN** — My Sancho welcomes you. Please use voice search and describe what you need in detail.

**RU** — My Sancho приветствует вас. Пожалуйста, воспользуйтесь голосовым поиском и подробно опишите, что вам нужно.

## Scripts — accepted

**AZ** — My Sancho sizin sorğunuzu qəbul etdi. Ətraflı məlumat çıxarılacaq.

**EN** — My Sancho has received your request. Matching details will appear shortly.

**RU** — My Sancho принял вашу заявку. Подробная информация появится в ближайшее время.

## Tips

- Export MP3 from ElevenLabs, then convert for iOS:

```bash
ffmpeg -y -i voice_greeting_az.mp3 -map_metadata -1 -vn -c:a aac -b:a 128k -ar 44100 -ac 1 voice_greeting_az.m4a
```

- Strip C2PA / huge ID3 tags (`-map_metadata -1`) — they can cause `(-11849) Operation Stopped` on iOS.
- After adding/changing audio files: **full stop + `flutter run`** (hot restart does not bundle new assets).
