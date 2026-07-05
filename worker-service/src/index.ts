import dotenv from 'dotenv';
import { createLogger } from './utils/logger';

dotenv.config();

const logger = createLogger();

logger.info('Worker service initialized. TODO: implement worker lifecycle and job processing.');
