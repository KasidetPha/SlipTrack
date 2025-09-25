// เดโม: profile เดียวทั้งระบบ
let profile = { displayName: 'SlipTrack User', avatar: null };

function getProfile(_req, res) {
  res.json({ success: true, profile });
}

function updateProfile(req, res) {
  const { displayName, avatar } = req.body || {};
  if (displayName) profile.displayName = displayName;
  if (avatar) profile.avatar = avatar;
  res.json({ success: true, profile });
}

module.exports = { getProfile, updateProfile };
