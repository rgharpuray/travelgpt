# BarkGPT Profile API Spec (for Django Backend)

## Overview
These endpoints support a richer profile experience in the BarkGPT app, before full authentication is added. All endpoints require the `Authorization` header.

---

## 1. Get Device Profile
**Endpoint:**
```
GET /barkgpt/profile/?device_id=<device_id>
```
**Returns:**
- `device_id`: string
- `pet_name`: string (optional)
- `profile_image_url`: string (optional)
- `cards_generated_normal`: int
- `cards_generated_intrusive`: int
- `total_likes`: int
- `date_joined`: ISO datetime string

**Example Response:**
```json
{
  "device_id": "abc123",
  "pet_name": "Argos",
  "profile_image_url": "https://.../argos.jpg",
  "cards_generated_normal": 12,
  "cards_generated_intrusive": 3,
  "total_likes": 42,
  "date_joined": "2024-06-01T12:34:56Z"
}
```

---

## 2. Update Pet Name
**Endpoint:**
```
POST /barkgpt/profile/update/
```
**Body:**
```json
{
  "device_id": "abc123",
  "pet_name": "NewName"
}
```
**Returns:** Updated profile object (see above).

---

## 3. Upload Profile Picture (Optional)
**Endpoint:**
```
POST /barkgpt/profile/upload_image/
```
**Body:**
- `device_id`: string
- `image`: file (multipart/form-data)

**Returns:**
```json
{
  "profile_image_url": "https://.../argos.jpg"
}
```

---

## 4. Field/Stat Calculation Notes
- `cards_generated_normal` and `cards_generated_intrusive` are counts of cards created by this device, split by mode.
- `total_likes` is the sum of likes on all cards for this device.
- `date_joined` is the first time this device was seen (or profile created).

---

## 5. Security
- All endpoints require the `Authorization` header with a valid token.

---

## 6. Example Django Model (for reference)
```python
class DeviceProfile(models.Model):
    device_id = models.CharField(max_length=64, unique=True)
    pet_name = models.CharField(max_length=64, blank=True, null=True)
    profile_image = models.ImageField(upload_to='profile_images/', blank=True, null=True)
    date_joined = models.DateTimeField(auto_now_add=True)

    def cards_generated_normal(self):
        return self.cards.filter(is_intrusive_mode=False).count()

    def cards_generated_intrusive(self):
        return self.cards.filter(is_intrusive_mode=True).count()

    def total_likes(self):
        return self.cards.aggregate(Sum('like_count'))['like_count__sum'] or 0
```

---

## 7. Example Django View (for reference)
```python
@api_view(['GET'])
def get_profile(request):
    device_id = request.GET.get('device_id')
    profile = get_object_or_404(DeviceProfile, device_id=device_id)
    data = {
        'device_id': profile.device_id,
        'pet_name': profile.pet_name,
        'profile_image_url': profile.profile_image.url if profile.profile_image else None,
        'cards_generated_normal': profile.cards_generated_normal(),
        'cards_generated_intrusive': profile.cards_generated_intrusive(),
        'total_likes': profile.total_likes(),
        'date_joined': profile.date_joined.isoformat(),
    }
    return Response(data)
```

---

*You can expand these as needed for your backend. Let me know if you want more detailed Django code or serializer examples!* 