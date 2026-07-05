const express = require('express');
const { body, param } = require('express-validator');
const { getPendingProposals, approveAndSchedule, rejectProposal } = require('../controllers/planEventController');
const { authenticate, authorize } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

const router = express.Router();
router.use(authenticate, authorize('Presidente'));

router.get('/proposals', getPendingProposals);

router.post('/approve/:propuestaId',
  [
    param('propuestaId').isUUID(),
    body('fecha').isDate(),
    body('hora').notEmpty(),
    body('lugar').notEmpty(),
  ],
  validateRequest, approveAndSchedule
);

router.post('/reject/:propuestaId',
  [param('propuestaId').isUUID()],
  validateRequest, rejectProposal
);

module.exports = router;