/// Full body stretching routine. `gif` is a file in `assets/gifs/`.
class Stretch {
  const Stretch(this.id, this.name, this.duration, this.description, this.instruction, this.gif);

  final String id;
  final String name;
  final String duration;
  final String description;
  final String instruction;
  final String gif;
}

const stretchingRoutine = <Stretch>[
  Stretch(
    'neck-rolls',
    'Neck Rolls',
    '30 seconds',
    'Gently rotate your head in circles',
    'Slowly roll your head clockwise, then counterclockwise. Keep shoulders relaxed.',
    '1403-x2chWLO.gif',
  ),
  Stretch(
    'neck-side-stretch',
    'Neck Side Stretch',
    '30 seconds each side',
    'Stretch neck and shoulder muscles',
    'Tilt head toward shoulder. Use gentle hand pressure. Breathe deeply.',
    '0716-oQRJYkC.gif',
  ),
  Stretch(
    'shoulder-rolls',
    'Shoulder Rolls',
    '30 seconds',
    'Roll shoulders backward to release tension',
    'Lift shoulders to ears, roll back and down. Repeat 10 times each direction.',
    '1259-QoHIhPl.gif',
  ),
  Stretch(
    'shoulder-blade-squeeze',
    'Shoulder Blade Squeeze',
    '30 seconds',
    'Strengthen and stretch upper back',
    'Squeeze shoulder blades together, hold 2 seconds. Release and relax.',
    '1271-Uto7l43.gif',
  ),
  Stretch(
    'chest-opener',
    'Chest Opener',
    '45 seconds each side',
    'Open up your chest and shoulders',
    'Clasp hands behind back, straighten arms, lift chest. Hold and breathe deeply.',
    '1167-3uj0Ozg.gif',
  ),
  Stretch(
    'tricep-stretch',
    'Tricep Stretch',
    '45 seconds each arm',
    'Release tension in back of arms',
    'Reach one arm overhead, bend elbow. Gently press elbow back with other hand.',
    '0643-Z5YStHW.gif',
  ),
  Stretch(
    'lat-stretch',
    'Lat Stretch',
    '45 seconds each side',
    'Stretch sides and latissimus dorsi',
    'Reach arm overhead and lean to opposite side. Feel stretch along side body.',
    '1346-f38OEuO.gif',
  ),
  Stretch(
    'wrist-forearm',
    'Wrist & Forearm Stretch',
    '30 seconds each arm',
    'Release wrist and forearm tightness',
    'Extend arm, press palm down with other hand. Reverse for back of forearm.',
    '0721-UtmIqcI.gif',
  ),
  Stretch(
    'cat-cow',
    'Cat-Cow Stretch',
    '1 minute',
    'Mobilize your entire spine',
    'On hands and knees: arch back (cow), then round spine (cat). Flow smoothly.',
    '2208-isofgzg.gif',
  ),
  Stretch(
    'child-pose',
    "Child's Pose",
    '1 minute',
    'Full body relaxation and back stretch',
    'Kneel, sit hips back to heels, extend arms forward. Rest forehead down.',
    '2204-XeMvLgE.gif',
  ),
  Stretch(
    'cobra-stretch',
    'Cobra Stretch',
    '45 seconds',
    'Open chest and stretch front of body',
    'Lie face down, push chest up with hands, keep hips on ground. Arch gently.',
    '3662-XPUDTt7.gif',
  ),
  Stretch(
    'forward-fold',
    'Forward Fold',
    '1 minute',
    'Stretch hamstrings and lower back',
    'Bend forward from hips. Let arms hang. Relax and let gravity do the work.',
    '1599-xTjr103.gif',
  ),
  Stretch(
    'quad-stretch',
    'Quadriceps Stretch',
    '45 seconds each leg',
    'Release tension in front thighs',
    'Standing, pull one foot to glutes. Keep knees together. Hold each leg.',
    '1713-YUYAMEj.gif',
  ),
  Stretch(
    'hamstring',
    'Hamstring Stretch',
    '1 minute each leg',
    'Loosen tight hamstrings',
    'Extend one leg, hinge at hips. Keep back straight. Feel the stretch behind thigh.',
    '1511-99rWm7w.gif',
  ),
  Stretch(
    'glute-stretch',
    'Glute Stretch',
    '45 seconds each side',
    'Release glute and hip tension',
    'Lying down, pull one knee to opposite shoulder. Hold and relax deeply.',
    '1424-DeDThfG.gif',
  ),
  Stretch(
    'hip-opener',
    'Hip Opener',
    '1 minute each side',
    'Release hip flexors and glutes',
    'Pigeon pose: one leg extended back, other bent forward. Sink hips down gently.',
    '1559-2LQkNPW.gif',
  ),
  Stretch(
    'butterfly-stretch',
    'Butterfly Stretch',
    '1 minute',
    'Open inner thighs and hips',
    'Sit, soles of feet together, knees out. Lean forward gently. Keep back straight.',
    '1494-bWlZvXh.gif',
  ),
  Stretch(
    'spinal-twist',
    'Spinal Twist',
    '45 seconds each side',
    'Decompress spine and improve mobility',
    'Seated or lying, cross one leg over, gently twist to opposite side.',
    '1363-JbC2iaV.gif',
  ),
  Stretch(
    'calf-stretch',
    'Calf Stretch',
    '45 seconds each leg',
    'Release tight calves',
    'Step back, heel down, lean forward. Keep leg straight. Feel stretch in calf.',
    '1398-qOKcgVP.gif',
  ),
  Stretch(
    'lower-back',
    'Lower Back Stretch',
    '1 minute',
    'Relieve lower back tension',
    'Lying on back, pull both knees to chest. Hold and breathe deeply.',
    '0690-QFmz6ch.gif',
  ),
];
